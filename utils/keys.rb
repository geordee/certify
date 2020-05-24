#!/usr/bin/env ruby

require "yaml"
require 'openssl'
require "active_support/core_ext"

CONFIG = YAML.load(File.read(File.join(__dir__, "..", "config.yml"))).deep_symbolize_keys
CN = CONFIG[:sign][:common_name]
OU = CONFIG[:sign][:organizational_unit]
O = CONFIG[:sign][:organization]
L = CONFIG[:sign][:location]
S = CONFIG[:sign][:state]
C = CONFIG[:sign][:country]
E = CONFIG[:sign][:email]

key = OpenSSL::PKey::RSA.new(1024)
public_key = key.public_key

subject = "/C=#{C}/O=#{O}/OU=#{OU}/CN=#{CN}"

cert = OpenSSL::X509::Certificate.new
cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
cert.not_before = Time.now
cert.not_after = Time.now + 365 * 24 * 60 * 60
cert.public_key = public_key
cert.serial = 0x0
cert.version = 2

ef = OpenSSL::X509::ExtensionFactory.new
ef.subject_certificate = cert
ef.issuer_certificate = cert
cert.extensions = [
  ef.create_extension("basicConstraints","CA:TRUE", true),
  ef.create_extension("keyUsage", "digitalSignature,keyCertSign", true),
  ef.create_extension("subjectKeyIdentifier", "hash"),
]

cert.sign key, OpenSSL::Digest::SHA1.new

File.open(File.join(__dir__, "..", CONFIG[:sign][:private_key]), "w") {
  |file| file.write(key)
} if CONFIG[:sign][:private_key].present?

File.open(File.join(__dir__, "..", CONFIG[:sign][:public_key]), "w") {
  |file| file.write(public_key)
} if CONFIG[:sign][:public_key].present?

File.open(File.join(__dir__, "..", CONFIG[:sign][:certificate]), "w") {
  |file| file.write(cert.to_pem)
} if CONFIG[:sign][:certificate].present?
