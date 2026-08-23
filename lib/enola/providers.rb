# frozen_string_literal: true

require "fileutils"
require "open3"
require "rbconfig"

module Enola
  # Prism and Rubydex are on by default. Prism runs as the vendored upstream
  # script under the Ruby running this gem; Rubydex is built into the binary
  # and needs its engine library fetched once per binary version.
  module Providers
    RUBYDEX_EXPECTED_VERSION = "0.4.0"

    def self.prism_script
      File.expand_path("providers/prism/enola_prism_provider.rb", __dir__)
    end

    def self.ruby
      RbConfig.ruby
    end

    def self.prism_version
      out, status = Open3.capture2(ruby, prism_script, "--version")
      status.success? ? out.strip : nil
    end

    def self.rubydex_expected_version(binary = nil)
      return RUBYDEX_EXPECTED_VERSION unless binary

      out, status = Open3.capture2(binary, "providers", "list")
      return RUBYDEX_EXPECTED_VERSION unless status.success?

      out[/rubydex\s+(\d+\.\d+\.\d+)/, 1] || RUBYDEX_EXPECTED_VERSION
    end

    # Runs `providers fetch rubydex` once per binary version; the outcome is
    # remembered beside the binary so a session never asks twice, and a
    # failure is a named skip the graph will also report, never silence.
    def self.ensure_rubydex(binary, channel: Enola.channel, cache_root: Enola.cache_root, stderr: $stderr)
      marker = File.join(channel.cache_dir(cache_root), "providers-rubydex")
      return File.read(marker).strip if File.exist?(marker)

      out, status = Open3.capture2e(binary, "providers", "fetch", "rubydex")
      outcome = status.success? ? "fetched" : "skipped: #{out.lines.last&.strip || 'providers fetch rubydex failed'}"
      stderr.puts "enola: rubydex #{outcome}; Rubydex facts will be a named skip in the receipt until it succeeds" unless status.success?
      FileUtils.mkdir_p(File.dirname(marker))
      File.write(marker, "#{outcome}\n")
      outcome
    rescue SystemCallError => e
      "skipped: #{e.message}"
    end
  end
end
