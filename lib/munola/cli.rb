# frozen_string_literal: true

require "optparse"

module Munola
  module CLI
    def self.start(argv, stdout: $stdout, stderr: $stderr)
      case argv.first
      when "--version"
        found = Munola.resolve
        out, = Open3.capture2e(found.path, "--version")
        stdout.puts Munola.channel_line(found)
        stdout.puts out.strip
        0
      when "init"
        init(argv.drop(1), stdout: stdout, stderr: stderr)
      else
        Enola::Runner.new(channel: CHANNEL, stderr: stderr).exec(argv)
      end
    rescue Enola::Error => e
      stderr.puts "munola: #{e.message}"
      127
    end

    def self.init(args, stdout:, stderr:)
      options = { tenant_column: nil }
      parser = OptionParser.new do |opts|
        opts.banner = "Usage: munola init [ROOT] [--tenant-column COLUMN]"
        opts.on("--tenant-column COLUMN", "The column most tables carry; confirmed against db/schema.rb") { |v| options[:tenant_column] = v }
      end
      rest = parser.parse(args)
      root = rest.first || Dir.pwd
      Installer.new(root, tenant_column: options[:tenant_column], stderr: stderr).install.lines.each { |line| stdout.puts line }
      0
    end
  end
end
