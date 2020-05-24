#!/usr/bin/env ruby

require "yaml"
require "openssl"
require "origami"
require "colorize"
require "active_support/core_ext"

include Origami

# load configuration
CONFIG = YAML.load(File.read(File.join(__dir__, "..", "config.yml"))).deep_symbolize_keys
CERT_FILE = File.join(__dir__, "..", CONFIG[:sign][:certificate])

pdfs = ARGV

if pdfs.empty?
  abort "Usage: verify input.pdf [...]"
end

cert = OpenSSL::X509::Certificate.new(File.read(CERT_FILE))

pdfs.each do |file|
  error = nil
  pdf = PDF.read(file, verbosity: Origami::Parser::VERBOSE_QUIET)
  result = pdf.verify(trusted_certs: [cert], allow_self_signed: true) do |ctx|
    error = ctx.error
  end
  if result then
    puts "#{"\u2713".encode('utf-8')} #{file}".green
  else
    puts "#{"\u2717".encode('utf-8')} #{file}".red
    puts "\tOpenSSL Error: #{error}".yellow if error
  end
end
