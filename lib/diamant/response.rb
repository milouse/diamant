# frozen_string_literal: true

require 'net/gemini/request'
require 'uri/gemini'

require_relative 'mimefile'

module Diamant
  # Methods to generate requests responses
  module Response
    class NotFound < Net::Gemini::BadResponse; end

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

    def build_response(client)
      r = Net::Gemini::Request.read_new(client)
      file_path = route r.path
      [r.uri, read_mime_file(file_path)]
    rescue NotFound => e
      @logger.warn "51 - #{e}"
      [r.uri, "51 Not found!\r\n"]
    rescue Net::Gemini::BadRequest, URI::InvalidURIError => e
      @logger.error "59 - #{e}"
      [nil, "59\r\n"]
    end

    def route(path)
      # In any case, remove the / prefix
      route = File.expand_path path.delete_prefix('/')
      # We better should use some sort of chroot...
      unless route.start_with?(Dir.pwd)
        raise NotFound, "Attempt to get something out of public_dir: #{route}"
      end

      route << '/index.gmi' if File.directory?(route)
      return route if File.exist?(route)

      raise NotFound, "File #{route} does not exist"
    end

    def read_mime_file(route)
      info = Diamant::MimeFile.new route
      header = "20 #{info.content_type}"
      [header, info.body].join("\r\n")
    rescue Diamant::MimeError => e
      @logger.error "50 - #{e}"
      "50 Not a supported file!\r\n"
    end
  end
end
