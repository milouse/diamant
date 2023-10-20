# frozen_string_literal: true

require 'net/gemini/request'
require 'uri/gemini'

module Diamant
  # Methods to generate requests responses
  module Response
    private

    def reject_request?(sock, current_load)
      # Accept only 10 thread with no restriction
      return false if current_load < 11
      # Seppuku
      raise 'Server is under heavy load' if current_load > 1965
      if current_load > 42
        @logger.warn '41 - Too much threads...'
        sock.puts "41 See you soon...\r\n"
        return true
      end
      # Please wait a little
      @logger.warn '44 5 - Too much threads...'
      sock.puts "44 5\r\n"
      true
    end

    def read_file(client)
      r = Net::Gemini::Request.read_new(client)
      [r.uri, route(r.path)]
    rescue Net::Gemini::BadRequest, URI::InvalidURIError
      [nil, ["59\r\n"]]
    end

    def route(path)
      # In any case, remove the / prefix
      route = File.expand_path path.delete_prefix('/'), Dir.pwd
      # We better should use some sort of chroot...
      unless route.start_with?(Dir.pwd)
        @logger.warn "Bad attempt to get something out of public_dir: #{route}"
        return ['51 Not found!']
      end
      route << '/index.gmi' if File.directory?(route)
      return ['51 Not found!'] unless File.exist?(route)
      build_response route
    end

    def build_response(route)
      info = Diamant::MimeType.new(route)
      answer = IO.readlines route, chomp: true
      answer.prepend "20 #{info.content_type}"
    rescue Diamant::MimeError
      ['50 Not a supported file!']
    end
  end
end
