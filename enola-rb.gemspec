# frozen_string_literal: true

require_relative "lib/enola_rb/version"

Gem::Specification.new do |spec|
  spec.name = "enola-rb"
  spec.version = EnolaRb::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "The Rails layer over the enola gem: rake tasks and a generator that writes the guides' starter laws."
  spec.description = <<~TEXT
    Adds the Rails layer to the enola gem: `rails generate enola:install` writes
    enola/constraints/ from the enola-guides starter laws and binds the recipes
    the released enola's own `constraints init` picks for the app, and the
    enola:init, enola:snapshot and enola:check rake tasks drive the binary the
    `enola` gem fetches and verifies. Pure Ruby; no binary, nothing compiled.
  TEXT
  spec.homepage = "https://github.com/misabegovic/enola-rb"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = [
    "LICENSE",
    "README.md",
    "CHANGELOG.md",
    "lib/enola-rb.rb",
    *Dir.glob("lib/enola_rb/*"),
    *Dir.glob("lib/generators/enola/**/*.rb")
  ]

  spec.add_dependency "enola", EnolaRb::VERSION
  spec.add_dependency "enola-guides", ">= 0.2.1"
end
