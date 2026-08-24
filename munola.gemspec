# frozen_string_literal: true

require_relative "lib/munola/version"

Gem::Specification.new do |spec|
  spec.name = "munola"
  spec.version = Munola::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "Runs a fork build of enola, not the enola-labs release: a channel of its own and a recipe catalogue bound by what the tree shows."
  spec.description = <<~TEXT
    The binary this gem fetches is not an enola-labs release. It is a build
    cut from https://github.com/misabegovic/enola, a fork of enola, whose
    release notes name what differs from upstream release by release; this
    gem drives channel release #{Munola::CHANNEL_VERSION}, built on enola
    #{Munola::UPSTREAM_VERSION}. Everything else is the enola gem's wrapper,
    unchanged: fetched on first use, verified against the checksums the
    release publishes, cached per user, every command and exit code
    forwarded. Use the enola gem to run stock upstream instead.

    What the fork adds: `munola init` writes the recipe catalogue the
    enola-guides gem carries (Ember, data ownership, API boundaries,
    background work, a tenant foreign key) into the project, binds the
    recipes its tree justifies, and turns both Ruby providers on by default.
    Under Rails it adds `rails generate munola:install`; the enola:* rake tasks come from enola-rb and drive munola's binary. Offered upstream where it fits;
    no binary here, nothing compiled.
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

  spec.add_dependency "enola", "~> 0.5.3"
  spec.add_dependency "enola-rb", "~> 0.5.3"
  spec.add_dependency "enola-guides", ">= 0.3.1"
end
