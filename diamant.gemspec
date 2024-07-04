# frozen_string_literal: true

require './lib/diamant/version'

Gem::Specification.new do |spec|
  spec.name        = 'diamant'
  spec.version     = Diamant::VERSION
  spec.summary     = 'A simple Gemini server for static files.'
  spec.description = <<~DESC
    Diamant is a server for the Gemini network protocol. It can only serve
    static files. Internally, it uses the OpenSSL library to handle the TLS
    sessions, and threads to handle concurrent requests.
  DESC
  spec.authors  = ['Étienne Deparis']
  spec.email    = 'etienne@depar.is'
  spec.metadata = {
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://git.umaneti.net/fronde',
    'homepage_uri' => 'https://etienne.depar.is/fronde/',
    'funding_uri' => 'https://liberapay.com/milouse'
  }
  spec.files = [
    'lib/diamant.rb',
    'lib/diamant/version.rb',
    'lib/diamant/cert_generator.rb',
    'lib/diamant/mimetype.rb',
    'lib/diamant/response.rb',
    # Others
    'LICENSE'
  ]
  spec.executables = ['diamant']
  spec.homepage    = 'https://git.umaneti.net/diamant/about/'
  spec.license     = 'WTFPL'

  spec.required_ruby_version = '>= 2.7'
  spec.add_runtime_dependency 'ruby-net-text', '~> 0.1'
end
