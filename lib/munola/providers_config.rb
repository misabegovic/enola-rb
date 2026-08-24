# frozen_string_literal: true

require "open3"
require "rbconfig"

module Munola
  # Every munola project runs both Ruby providers by default: Prism through the
  # script the enola gem carries, Rubydex built into the binary. The config is
  # written once, never rewritten; the Rubydex library is fetched after the
  # binary, and a fetch that fails is a named skip, never a silent absence.
  module ProvidersConfig
    RUBYDEX_VERSION = "0.4.0"

    def self.write(root, ruby: RbConfig.ruby)
      path = File.join(root, "mcp-arch.yaml")
      return nil if File.exist?(path)

      File.write(path, render(ruby))
      path
    end

    def self.render(ruby)
      lines = ["repo: .", "repos:", "  - .", "providers:"]
      script = prism_script
      if script
        lines += ["  - name: prism", "    command: [#{ruby.inspect}, #{script.inspect}]", "    expected_version: \"0.1.0\""]
      else
        lines << "  # prism: the enola gem on this machine carries no provider script; add one here to run it"
      end
      lines += ["  - name: rubydex", "    expected_version: \"#{RUBYDEX_VERSION}\""]
      "#{lines.join("\n")}\n"
    end

    def self.prism_script
      return nil unless defined?(Enola::Providers) && Enola::Providers.respond_to?(:prism_script)

      script = Enola::Providers.prism_script
      script if script && File.exist?(script)
    end

    def self.fetch_rubydex(binary)
      out, status = Open3.capture2e(binary, "providers", "fetch", "rubydex")
      return "rubydex #{RUBYDEX_VERSION} library in place" if status.success?

      "rubydex library not fetched (#{out.lines.last.to_s.strip}); the provider reads as a named skip until `enola providers fetch rubydex` succeeds"
    rescue SystemCallError => e
      "rubydex library not fetched (#{e.message}); the provider reads as a named skip until `enola providers fetch rubydex` succeeds"
    end
  end
end
