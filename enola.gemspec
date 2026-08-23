# frozen_string_literal: true

require_relative "lib/enola/version"

Gem::Specification.new do |spec|
  spec.name = "enola"
  spec.version = Enola::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "Runs the released enola from Ruby: fetched on first use, verified, pinned to this gem's version."
  spec.description = <<~TEXT
    A pure-Ruby wrapper around enola, the architecture-graph tool by enola-labs.
    The gem's version is the upstream release it drives. The binary is not in
    the gem: the first command that needs it downloads the release for your
    platform, verifies it against the checksum the release publishes, and keeps
    it in a per-user cache. Every command and exit code is forwarded unchanged.
    This gem is not an enola-labs release.
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
    "lib/enola.rb",
    *Dir.glob("lib/enola/*.rb"),
    *Dir.glob("lib/enola/providers/**/*.rb")
  ]

  spec.add_dependency "prism", ">= 1.3"
  spec.bindir = "exe"
  spec.executables = ["enola"]
end
