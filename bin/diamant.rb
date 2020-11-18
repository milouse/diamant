#!/usr/bin/env -S ruby -I lib
# frozen_string_literal: true

require 'diamant'
require 'optparse'

options = { hostname: '127.0.0.1', port: 1965, public_path: './public_gmi' }
OptionParser.new do |parser| # rubocop:disable Metrics/BlockLength
  parser.banner = "Usage: #{parser.program_name} [options]"

  parser.on('-h', '--help',
            'Show this help message and quit.') do
    puts parser.help
    exit
  end

  parser.on('-v', '--version',
            "Show #{parser.program_name} version and quit.") do
    puts Diamant::VERSION
    exit
  end

  parser.on('-b', '--bind HOST',
            'Hostname to bind to (127.0.0.1, 0.0.0.0, ::1...).',
            '(defaults to 127.0.0.1)') do |o|
    options[:bind] = o
  end

  parser.on('-p', '--port PORT',
            'Define the TCP port to bind to.',
            '(defaults to 1965)') do |o|
    options[:port] = o.to_i
  end

  parser.on('--public-path PATH',
            'Path from where to serve files.',
            '(defaults to ./public_gmi)') do |o|
    options[:public_path] = o
  end

  parser.on('--cert CERT',
            'Path to the TLS certificate to use.',
            '(defaults to cert.pem)') do |o|
    options[:cert] = o
  end

  parser.on('--pkey PKEY',
            'Path to the TLS private key to use.',
            '(defaults to key.rsa)') do |o|
    options[:pkey] = o
  end
end.parse!

Diamant::Server.new(options).start
