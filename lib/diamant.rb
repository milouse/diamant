# frozen_string_literal: true

require 'logger'
require 'socket'
require 'English'
require 'openssl'
require 'fileutils'

require 'uri/gemini'

module Diamant
  class Server
    def initialize(opts = {})
      @port = opts[:port] || 1965
      @cert = opts[:cert] || 'cert.pem'
      @pkey = opts[:pkey] || 'key.rsa'
      @logger = Logger.new($stdout)
    end

    def start
      tcp_serv = TCPServer.new @port
      ssl_serv = OpenSSL::SSL::SSLServer.new tcp_serv, ssl_context
      loop do
        Thread.new(ssl_serv.accept) do |client|
          handle_client(client)
          client.close
        end
      rescue Interrupt
        break
      end

      ssl_serv.shutdown
    end

    private

    def handle_client(client)
      # Read up to 1026 bytes:
      # - 1024 bytes max for the URL
      # - 2 bytes for <CR><LF>
      str = client.gets($INPUT_RECORD_SEPARATOR, 1026)
      m = /\A(.*)\r\n\z/.match(str)
      if m.nil?
        @logger.warn "Malformed request: #{str.dump}"
        client.puts "59\r\n"
        return
      end
      uri = URI(m[1])
      @logger.info "Received #{uri}"
      client.puts "20 text/gemini\r\n"
      client.puts "I got #{uri.path}"
    end

    def ssl_context
      ssl_context = OpenSSL::SSL::SSLContext.new
      ssl_context.min_version = OpenSSL::SSL::TLS1_2_VERSION
      raw_cert = File.read File.expand_path(@cert)
      cert = OpenSSL::X509::Certificate.new raw_cert
      raw_key = File.read File.expand_path(@pkey)
      pkey = OpenSSL::PKey::RSA.new raw_key
      ssl_context.add_certificate cert, pkey
      ssl_context
    end
  end
end
