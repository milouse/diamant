# frozen_string_literal: true

require './lib/diamant/version'

Gem::Specification.new do |s|
  s.name        = 'diamant'
  s.version     = Diamant::VERSION
  s.summary     = 'A simple Gemini server for static files.'
  s.description = <<~DESC
    Diamant is a server for the Gemini network protocol. it
    can only serve static files. Internally, it uses the OpenSSL library to
    handle the TLS sessions, and threads to handle concurrent requests.
  DESC
  s.authors     = ['Étienne Deparis']
  s.email       = 'etienne@depar.is'
  s.files       = ['lib/diamant.rb',
                   'lib/diamant/version.rb',
                   'lib/diamant/cert_generator.rb',
                   # Others
                   'LICENSE']
  s.executables = ['diamant']
  s.homepage    = 'https://git.umaneti.net/diamant/about/'
  s.license     = 'WTFPL'

  s.required_ruby_version = '>= 2.7'
  s.add_runtime_dependency 'ruby-net-text', '~> 0.0.2'

  s.add_development_dependency 'byebug', '~> 11.1'
  s.add_development_dependency 'pry', '~> 0.13'
  s.add_development_dependency 'pry-doc', '~> 1.1'
  s.add_development_dependency 'rspec', '~> 3.9'
  s.add_development_dependency 'rubocop', '~> 1.3'
  s.add_development_dependency 'rubocop-performance', '~> 1.9'
  s.add_development_dependency 'rubocop-rspec', '~> 2.0'
  s.add_development_dependency 'simplecov', '~> 0.19'
  s.add_development_dependency 'yard', '~> 0.9'
end
