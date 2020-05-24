#!/usr/bin/env ruby

require "time"
require "yaml"
require "openssl"
require "origami"
require "colorize"
require "active_support/core_ext"

include Origami

# load configuration
CONFIG = YAML.load(File.read(File.join(__dir__, "..", "config.yml"))).deep_symbolize_keys
CERT_FILE = File.join(__dir__, "..", CONFIG[:sign][:certificate])
KEY_FILE = File.join(__dir__, "..", CONFIG[:sign][:private_key])

CN = CONFIG[:sign][:common_name]
OU = CONFIG[:sign][:organizational_unit]
O = CONFIG[:sign][:organization]
L = CONFIG[:sign][:location]
S = CONFIG[:sign][:state]
C = CONFIG[:sign][:country]
E = CONFIG[:sign][:email]
REASON = CONFIG[:sign][:reason]

key = OpenSSL::PKey::RSA.new(File.read(KEY_FILE))
cert = OpenSSL::X509::Certificate.new(File.read(CERT_FILE))

Dir.glob(File.join(__dir__, "..", CONFIG[:paths][:output], "**", "*.pdf")) do |file|
  next if file.end_with?("_Signed.pdf")

  puts "Signing #{file}".blue

  output_filename = file.dup.insert(file.rindex("."), "_Signed")

  pdf = PDF.read(file, verbosity: Origami::Parser::VERBOSE_QUIET)
  page = pdf.get_page(1)

  width = 160.0
  height = 16.0
  x = page.MediaBox[2].to_f - width - height
  y = height
  size = 8

  now = Time.now

  text_annotation = Annotation::AppearanceStream.new
  text_annotation.Type = Origami::Name.new("XObject")
  text_annotation.Resources = Resources.new
  text_annotation.Resources.ProcSet = [Origami::Name.new("Text")]
  text_annotation.set_indirect(true)
  text_annotation.Matrix = [ 1, 0, 0, 1, 0, 0 ]
  text_annotation.BBox = [ 0, 0, width, height ]
  text_annotation.write("Signed at #{now.iso8601}", x: size, y: (height/2)-(size/2), size: size)

  # Add signature annotation (so it becomes visibles in PDF document)
  signature_annotation = Annotation::Widget::Signature.new
  signature_annotation.Rect = Rectangle[llx: x, lly: y+height, urx: x+width, ury: y]
  signature_annotation.F = Annotation::Flags::PRINT
  signature_annotation.set_normal_appearance(text_annotation)

  page.add_annotation(signature_annotation)

  # Sign the PDF with the specified keys
  pdf.sign(cert, key,
    method: "adbe.pkcs7.sha1",
    annotation: signature_annotation,
    location: L,
    contact: E,
    reason: REASON
  )

  # Save the resulting file
  pdf.save(output_filename)
end
