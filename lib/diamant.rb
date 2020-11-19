# frozen_string_literal: true

require 'logger'
require 'socket'
require 'English'
require 'openssl'
require 'fileutils'

require 'net/gemini/request'
require 'uri/gemini'

require 'diamant/version'
require 'diamant/mimetype'

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
      loop do
        Thread.new(ssl_serv.accept) do |client|
          handle_client(client)
          client.close
        end
      rescue Interrupt
        break
      end
    ensure
      ssl_serv&.shutdown
    end

    private

    def handle_client(client)
      begin
        r = Net::GeminiRequest.read_new(client)
      rescue Net::GeminiBadRequest
        client.puts "59\r\n"
        return
      end
      answer = route(r.path)
      @logger.info "#{answer[0]} - #{r.uri}"
      answer.each do |line|
        client.puts "#{line}\r\n"
      end
    end

    def build_response(route)
      info = Diamant::MimeType.new(route)
      answer = IO.readlines route, chomp: true
      answer.prepend "20 #{info.content_type}"
    rescue Diamant::MimeError
      ['50 Not a supported file!']
    end

    def route(path)
      # Avoid answer code 50 for domain name only request
      path = '/index.gmi' if path == ''
      file_path = [@public_path, path]
      file_path << 'index.gmi' if path.end_with?('/')
      route = file_path.join
      return ['51 Not found!'] unless File.exist?(route)
      build_response route
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
      @public_path = check_option_path_exist(
        opts[:public_path], './public_gmi'
      ).delete_suffix('/')
      cert_file = check_option_path_exist(opts[:cert], 'cert.pem')
      @cert = OpenSSL::X509::Certificate.new File.read(cert_file)
      key_file = check_option_path_exist(opts[:pkey], 'key.rsa')
      @pkey = OpenSSL::PKey::RSA.new File.read(key_file)
    end
  end
end
