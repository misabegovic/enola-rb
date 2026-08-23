# frozen_string_literal: true

module EnolaRb
  # The enola-guides gem carries the starter laws; it is found at run time so a
  # missing gem is a refusal naming the Gemfile line rather than a load error.
  module Guides
    BUILT_IN_RECIPES = %w[
      rails-conventions rails-strict vanilla-rails layered ports-and-adapters
      modular-monolith event-driven clean cqrs ruby-conventions
    ].freeze

    def self.root
      ENV.fetch("ENOLA_GUIDES_DIR") { Gem::Specification.find_by_name("enola-guides").gem_dir }
    rescue Gem::MissingSpecError
      raise Enola::Unavailable, "the enola-guides gem is not installed; add `gem \"enola-guides\"` to the Gemfile, it carries the starter laws the generator writes"
    end

    def self.starter_laws
      Dir.glob(File.join(root, "templates", "constraints-starter", "*.rb")).sort
    end
  end
end
