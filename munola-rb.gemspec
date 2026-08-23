# frozen_string_literal: true

require_relative "lib/munola/version"

Gem::Specification.new do |spec|
  spec.name = "munola-rb"
  spec.version = Munola::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "The Rails layer over the munola gem: the generator that writes the recipe catalogue an app has a need for."
  spec.description = <<~TEXT
    What enola-rb is to the enola gem, this is to munola: `rails generate
    munola:install` writes enola/constraints/ from the starter laws, binds the
    recipes the binary's own init picks, then writes the munola catalogue and
    binds the recipes the tree justifies, filling the tenant foreign key from
    db/schema.rb when a column names one. The enola:init, enola:snapshot and
    enola:check rake tasks come from enola-rb and drive munola's binary,
    because munola installs its own resolver. Pure Ruby; no binary, nothing
    compiled.
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
    "lib/munola-rb.rb",
    *Dir.glob("lib/munola_rb/*"),
    *Dir.glob("lib/generators/munola/**/*.rb")
  ]

  spec.add_dependency "enola-rb", Munola::UPSTREAM_VERSION
  spec.add_dependency "munola", Munola::VERSION
end
