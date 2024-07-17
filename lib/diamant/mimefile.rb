# frozen_string_literal: true

module Diamant
  class MimeError < StandardError; end

  # MIME aware wrapper for file
  class MimeFile
    attr_reader :body, :category, :content_type, :extension

    MIMETYPES = {
      '.gemini' => 'text/gemini',
      '.gmi' => 'text/gemini',
      '.txt' => 'text/plain',
      '.md' => 'text/markdown',
      '.org' => 'text/org',
      '.rss' => 'application/rss+xml',
      '.atom' => 'application/atom+xml',
      '.xml' => 'application/xml',
      '.svg' => 'image/svg+xml',
      '.bmp' => 'image/bmp',
      '.png' => 'image/png',
      '.jpg' => 'image/jpeg',
      '.jpeg' => 'image/jpeg',
      '.gif' => 'image/gif',
      '.webp' => 'image/webp',
      '.mp3' => 'audio/mpeg',
      '.ogg' => 'audio/ogg'
    }.freeze

    def initialize(path)
      @path = path
      @body = File.read path
      @extension, @content_type = extract_info
      @category = classify
      validate!
      prepare_gem_file if @content_type == 'text/gemini'
    end

    # Disable metrics on purpose for big switch
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
    def validate
      return true if @category == :text

      case @content_type
      when 'image/jpeg'
        @body[0..1] == "\xFF\xD8"
      when 'image/png'
        @body[0..7] == "\x89PNG\r\n\u001A\n"
      when 'image/gif'
        @body[0..2] == 'GIF'
      when 'image/webp'
        @body[0..3] == 'RIFF' && @body[8..11] == 'WEBP'
      when 'image/bmp'
        @body[0..2] == 'BM'
      when 'image/svg+xml', 'application/xml',
           'application/rss+xml', 'application/atom+xml'
        @body[0..5] == '<?xml '
      when 'audio/mpeg'
        @body[0..3] == 'ID3'
      when 'audio/ogg'
        @body[0..4] == 'OggS'
      else
        false
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

    def validate!
      return if validate

      raise MimeError, "#{@path} does not looks like a #{@content_type} file!"
    end

    private

    def extract_info
      extension = File.extname @path
      mime = MIMETYPES[extension]
      raise MimeError, "#{@path} format is not supported!" if mime == ''

      # Any other supported extension
      [extension, mime]
    end

    def classify
      return unless @content_type

      @content_type.split('/', 2).first.to_sym
    end

    def prepare_gem_file
      # Ensure each lines finishes with \r\n
      @body = @body.each_line(chomp: true).to_a.join "\r\n"
    end
  end
end
