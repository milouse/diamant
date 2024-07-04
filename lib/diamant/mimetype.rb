# frozen_string_literal: true

module Diamant
  class MimeError < StandardError; end

  # Helper to understand what mimetype has a given file
  class MimeType
    attr_reader :extension, :content_type

    MIMETYPES = {
      '.gemini' => 'text/gemini',
      '.gmi' => 'text/gemini',
      '.txt' => 'text/plain',
      '.md' => 'text/markdown',
      '.org' => 'text/org',
      '.xml' => 'application/xml',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif'
    }.freeze

    def initialize(path)
      @path = path
      extract_info
    end

    def supported?
      @extension != '' && MIMETYPES.has_key?(@extension)
    end

    private

    def extract_info
      @extension = File.extname @path
      raise MimeError, "#{@path} format is not supported!" unless supported?

      # Any other supported extension
      @content_type = MIMETYPES[@extension]
    end
  end
end
