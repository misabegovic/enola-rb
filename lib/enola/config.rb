# frozen_string_literal: true

module Enola
  module Config
    FILE = "mcp-arch.yaml"

    IGNORE = %w[**/.git/** **/node_modules/** **/vendor/** **/tmp/** **/log/** **/coverage/** **/public/assets/**].freeze

    def self.path(root)
      File.join(File.expand_path(root), FILE)
    end

    def self.write_default(root, ruby: Providers.ruby)
      target = path(root)
      return nil if File.exist?(target)

      File.write(target, render(ruby: ruby))
      target
    end

    def self.render(ruby: Providers.ruby)
      <<~YAML
        # Written by the enola gem; edit freely. Both providers are on by default:
        # Prism runs under the Ruby that runs the gem, Rubydex is built into the
        # binary and fetched once. Remove one to leave it out of the graph.
        repo: .
        repos:
          - .
        ignore:
        #{IGNORE.map { |glob| "  - \"#{glob}\"" }.join("\n")}
        providers:
          - name: prism
            command: [#{ruby.inspect}, #{Providers.prism_script.inspect}]
            expected_version: "#{Providers.prism_version || '0.1.0'}"
          - name: rubydex
            expected_version: "#{Providers::RUBYDEX_EXPECTED_VERSION}"
      YAML
    end
  end
end
