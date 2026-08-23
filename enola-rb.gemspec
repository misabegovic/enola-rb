# frozen_string_literal: true

require_relative "lib/enola-rb"

Gem::Specification.new do |spec|
  spec.name = "enola-rb"
  spec.version = EnolaRb::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "Runs enola from Ruby, with defaults chosen for Rails stacks."
  spec.description = <<~TEXT
    A Ruby wrapper around enola, the architecture-graph tool: presets, defaults
    and a command surface aimed at Rails applications. Drives whichever enola
    binary is on your path; add the munola gem to use the build this project
    ships instead. Placeholder release; no implementation yet.
  TEXT
  spec.homepage = "https://github.com/misabegovic/enola-rb"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = [
    "LICENSE",
    "README.md",
    "lib/enola-rb.rb",
    "lib/enola_rb/version.rb"
  ]
end
