# frozen_string_literal: true

require_relative "lib/munola"

Gem::Specification.new do |spec|
  spec.name = "munola"
  spec.version = Munola::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "Ships the enola build that enola-rb runs when upstream lacks a capability."
  spec.description = <<~TEXT
    Carries a build of enola, the architecture-graph tool, for projects that
    want capabilities not yet in an upstream release. Installing it alongside
    enola-rb switches that gem from the stock binary to this one. Placeholder
    release; no binary yet.
  TEXT
  spec.homepage = "https://github.com/misabegovic/enola-rb"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.files = [
    "LICENSE",
    "README.md",
    "lib/munola.rb"
  ]
end
