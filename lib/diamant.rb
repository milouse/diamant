# frozen_string_literal: true

require 'logger'
require 'socket'
require 'English'
require 'openssl'
require 'fileutils'

require 'diamant/version'
require 'diamant/mimetype'
require 'diamant/response'

module Diamant
  # Runs the server request/answer loop.
  class Server
    def initialize(opts = {})
      @port = opts[:port] || 1965
      @bind = opts[:bind] || '127.0.0.1'
      init_logger
      init_server_paths(opts)
    end

    def start
      tcp_serv = TCPServer.new @bind, @port
      ssl_serv = OpenSSL::SSL::SSLServer.new tcp_serv, ssl_context
      main_loop(ssl_serv)
    ensure
      ssl_serv&.shutdown
    end

    private

    include Diamant::Response

    def main_loop(ssl_serv)
      loop do
        Thread.new(ssl_serv.accept) do |client|
          handle_client(client)
        rescue Errno::ECONNRESET, Errno::ENOTCONN => e
          @logger.error(e.message)
        ensure
          client.close
        end
      rescue OpenSSL::SSL::SSLError => e
        # Do not even try to answer anything as the socket cannot be
        # built. This will abruptly interrupt the connection from a client
        # point of view, which must deal with it. Only keep a trace for us.
        @logger.error(
          format('SSLError: %<cause>s',
                 cause: e.message.sub(/.*state=error: (.+)\Z/, '\1'))
        )
      rescue Errno::ECONNRESET
        @logger.error('Connection reset by peer')
      rescue Interrupt
        break
      end
    end

    def handle_client(client)
      current_load = Thread.list.length - 1
      return if reject_request?(client, current_load)
      uri, answer = read_file(client)
      log_line = [current_load, client.peeraddr[3], answer[0]]
      log_line << uri if uri
      @logger.info log_line.join(' - ')
      answer.each do |line|
        client.puts "#{line}\r\n"
      end
    end

    def ssl_context
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.min_version = OpenSSL::SSL::TLS1_2_VERSION
      ssl_context.add_certificate @cert, @pkey
      ssl_context
    end

    def init_logger
      $stdout.sync = true
      @logger = Logger.new($stdout)
      @logger.datetime_format = '%Y-%m-%d %H:%M:%S'
      @logger.formatter = proc do |severity, datetime, _, msg|
        "[#{datetime}] #{severity}: #{msg}\n"
      end
    end

    def check_option_path_exist(option, default)
      path = File.expand_path(option || default)
      return path if File.exist?(path)
      raise ArgumentError, "#{path} does not exist!"
    end

    def init_server_paths(opts = {})
      cert_file = check_option_path_exist(opts[:cert], 'cert.pem')
      @cert = OpenSSL::X509::Certificate.new File.read(cert_file)
      key_file = check_option_path_exist(opts[:pkey], 'key.rsa')
      @pkey = OpenSSL::PKey::RSA.new File.read(key_file)
      public_path = check_option_path_exist(
        opts[:public_path], './public_gmi'
      )
      Dir.chdir(public_path)
    end
  end
end
