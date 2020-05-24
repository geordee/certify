#!/usr/bin/env ruby

require "csv"
require "date"
require "yaml"
require "prawn"
require "colorize"
require "fileutils"
require "active_support/core_ext"

# load configuration
CONFIG = YAML.load(File.read(File.expand_path('config.yml', __dir__))).deep_symbolize_keys

groups_path = File.join(CONFIG[:paths][:data], CONFIG[:paths][:groups])
groups = Pathname.new(groups_path)
                 .children
                 .select { |c| c.directory? }
                 .collect { |p| p.to_s }

# process
groups.each do |group_path|

  group = File.basename(group_path)
  puts "Processing group #{group}".cyan

  subgroups_path = File.join(group_path, CONFIG[:paths][:subgroups])
  subgroups = Pathname.new(subgroups_path)
                     .children
                     .select { |c| c.file? && File.extname(c).downcase == ".csv"}
                     .collect { |p| p.to_s }

  subgroups.each do |subgroup_file|

    subgroup = File.basename(subgroup_file, ".csv")
    puts "\tProcessing subgroup #{subgroup}".blue

    subgroup_dir = File.join(CONFIG[:paths][:output],
                            CONFIG[:paths][:groups],
                            group,
                            CONFIG[:paths][:subgroups],
                            subgroup)
    FileUtils.mkdir_p subgroup_dir

    options = { encoding: 'UTF-8', skip_blanks: true, headers: true }

    CSV.open(subgroup_file, mode = "r", **options) do |file|

      file.each.with_index(1) do |row, index|
        puts "\t\t#{(index).to_s.rjust(2, " ")}. #{row[0]}".green
        issued_to = row[0]
        issued_for = row[1].presence || CONFIG[:issued][:for]
        issued_on = CONFIG[:issued][:date].presence || Date.today.iso8601

        filename = "#{subgroup_dir}/#{issued_to.parameterize.split("-").map(&:titleize).join("-")}.pdf"

        Prawn::Document.generate(filename,
                page_size: CONFIG[:page][:size],
                page_layout: CONFIG[:page][:layout].to_sym,
                margin: 0) do |pdf|

          pdf.image CONFIG[:page][:background],
            at: [0, CONFIG[:page][:height]],
            fit: [CONFIG[:page][:width], CONFIG[:page][:height]]

          pdf.move_up CONFIG[:page][:height]

          pdf.font CONFIG[:font][:normal]
          pdf.text_box issued_to,
            at: [0,365],
            width: CONFIG[:page][:width],
            align: :center,
            size: 32

          pdf.font CONFIG[:font][:normal]
          pdf.text_box "#{group.upcase}#{subgroup.upcase}",
            at: [0,320],
            width: CONFIG[:page][:width],
            align: :center,
            size: 20

          pdf.font CONFIG[:font][:normal]
          pdf.text_box issued_for,
            at: [0,260],
            width: CONFIG[:page][:width],
            align: :center,
            size: 26

          pdf.font CONFIG[:font][:normal]
          pdf.text_box issued_on,
            at: [0,220],
            width: CONFIG[:page][:width],
            align: :center,
            size: 20

          pdf.font CONFIG[:font][:normal]
          pdf.text_box CONFIG[:signatory][:first][:name],
            at: [-180,125],
            width: CONFIG[:page][:width],
            align: :center,
            size: 24

          pdf.font "Helvetica"
          pdf.text_box CONFIG[:signatory][:first][:title],
            at: [-180,90],
            width: CONFIG[:page][:width],
            align: :center,
            size: 14

          pdf.font CONFIG[:font][:normal]
          pdf.text_box CONFIG[:signatory][:second][:name],
            at: [180,125],
            width: CONFIG[:page][:width],
            align: :center,
            size: 24

          pdf.font "Helvetica"
          pdf.text_box CONFIG[:signatory][:second][:title],
            at: [180,90],
            width: CONFIG[:page][:width],
            align: :center,
            size: 14

        end
      end
    end
  end
end
