# frozen_string_literal: true

require 'openssl'

module Diamant
  # Creates a new self-signed certificate and its related RSA private key,
  # suitable to be used as certificate for the Gemini network protocol.
  #
  # This Generator is not intended to advance use as it offers no
  # configuration at all. It use the following options:
  #
  # - 4096 bits RSA key
  # - 1 year validity
  # - self signed certificate
  #
  class CertGenerator
    def initialize(subject = 'localhost')
      @subject = OpenSSL::X509::Name.parse "/CN=#{subject}"
      @key = OpenSSL::PKey::RSA.new 4096
      init_cert
      add_extensions
      @cert.sign @key, OpenSSL::Digest.new('SHA256')
    end

    def write
      IO.write('key.rsa', @key.to_pem)
      File.chmod(0o400, 'key.rsa')
      IO.write('cert.pem', @cert.to_pem)
      File.chmod(0o644, 'cert.pem')
    end

    private

    def init_cert
      @cert = OpenSSL::X509::Certificate.new
      @cert.version = 3
      @cert.serial = 0x0
      @cert.issuer = @subject
      @cert.subject = @subject
      @cert.public_key = @key.public_key
      @cert.not_before = Time.now
      # 1 years validity
      @cert.not_after = @cert.not_before + 1 * 365 * 24 * 60 * 60
      @cert
    end

    def add_extension_to_cert(ext_factory, name, value, critical: false)
      @cert.add_extension(
        ext_factory.create_extension(name, value, critical)
      )
    end

    def add_extensions
      ef = OpenSSL::X509::ExtensionFactory.new
      ef.subject_certificate = @cert
      ef.issuer_certificate = @cert
      add_extension_to_cert(
        ef, 'basicConstraints', 'CA:TRUE', critical: true
      )
      add_extension_to_cert(ef, 'subjectKeyIdentifier', 'hash')
      add_extension_to_cert(
        ef, 'authorityKeyIdentifier', 'keyid:always,issuer:always'
      )
    end
  end
end
