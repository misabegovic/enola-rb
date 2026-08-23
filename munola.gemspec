# frozen_string_literal: true

require_relative "lib/munola/version"

Gem::Specification.new do |spec|
  spec.name = "munola"
  spec.version = Munola::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "One person's taste on top of enola: a channel of its own and a recipe catalogue bound by what the tree shows."
  spec.description = <<~TEXT
    The same pure-Ruby wrapper as the enola gem over another channel: the
    builds cut from a fork of enola, versioned as the upstream they are built
    on plus a fourth segment, each release naming what differs. `munola init`
    writes the recipe catalogue the enola-guides gem carries (Ember, data
    ownership, API boundaries, background work, a tenant foreign key) into
    the project and binds the recipes its tree justifies, and turns both Ruby
    providers on by default. Offered upstream where it fits; no binary here,
    nothing compiled.
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
    "lib/munola.rb",
    *Dir.glob("lib/munola/*"),
    *Dir.glob("lib/generators/munola/**/*.rb")
  ]
  spec.bindir = "exe"
  spec.executables = ["munola"]

  spec.add_dependency "enola", Munola::UPSTREAM_VERSION
  spec.add_dependency "enola-rb", Munola::UPSTREAM_VERSION
  spec.add_dependency "enola-guides", ">= 0.3.1"
end
