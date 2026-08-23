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
        # Written by the enola gem; edit freely. Prism is on by default and runs
        # under the Ruby that runs the gem. Rubydex is left off: the release this
        # gem drives has a walk that can fail to return on a tree with vendored
        # gems, fixed but not yet in a published enola. Uncomment it to run it
        # anyway, and expect a snapshot that may not finish.
        repo: .
        repos:
          - .
        ignore:
        #{IGNORE.map { |glob| "  - \"#{glob}\"" }.join("\n")}
        providers:
          - name: prism
            command: [#{ruby.inspect}, #{Providers.prism_script.inspect}]
            expected_version: "#{Providers.prism_version || '0.1.0'}"
        # - name: rubydex
        #   expected_version: "#{Providers::RUBYDEX_EXPECTED_VERSION}"
      YAML
    end
  end
end
