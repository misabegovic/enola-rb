# frozen_string_literal: true

require_relative "lib/enola"

Gem::Specification.new do |spec|
  spec.name = "enola"
  spec.version = EnolaPlaceholder::VERSION
  spec.authors = ["Muhamed Isabegovic"]
  spec.email = ["m.isabegovic@hotmail.com"]

  spec.summary = "Name placeholder held for the enola project; not an official release."
  spec.description = <<~TEXT
    This gem is a placeholder, not an implementation. enola is an
    architecture-graph tool written in Go by enola-labs, which has no Ruby
    package. This name is held so that it stays available to that project, and
    will be transferred to its maintainers on request. For Ruby usage today,
    see the enola-rb gem.
  TEXT
  spec.homepage = "https://github.com/enola-labs/enola"
  spec.license = "Apache-2.0"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = "https://github.com/misabegovic/enola-rb"

  spec.files = [
    "LICENSE",
    "README.md",
    "lib/enola.rb"
  ]
end
