# frozen_string_literal: true

require 'logger'
require 'socket'
require 'English'
require 'openssl'
require 'fileutils'

require 'net/gemini/request'
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
    ensure
      ssl_serv.shutdown
    end

    private

    def handle_client(client)
      begin
        r = Net::GeminiRequest.read_new(client)
      rescue Net::GeminiBadRequest
        client.puts "59\r\n"
        return
      end
      @logger.info "Received #{r.uri}"
      client.puts "20 text/gemini\r\n"
      client.puts "I got #{r.path}"
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
