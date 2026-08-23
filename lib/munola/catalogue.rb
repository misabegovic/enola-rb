# frozen_string_literal: true

require "fileutils"

module Munola
  # The recipes munola ships built in, read from the enola-guides gem so the
  # content has one version line; the template carries a value the installer
  # fills in from what the app shows.
  module Catalogue
    RECIPES = %w[ember-conventions data-ownership api-boundaries background-work tenant-foreign-key].freeze
    TEMPLATES = %w[tenant-foreign-key].freeze
    PLACEHOLDERS = { column: "TENANT_COLUMN", table: "TENANT_TABLE" }.freeze

    def self.source_dir
      File.join(EnolaRb::Guides.root, "recipes")
    end

    def self.source(name)
      path = File.join(source_dir, "#{name}.yaml")
      raise Enola::Unavailable, "the installed enola-guides gem has no recipe #{name}; it needs 0.3.1 or later" unless File.exist?(path)

      path
    end

    # Writes every catalogue recipe the project does not already have into
    # enola/recipes/, the template with its values filled or, without them,
    # left as it is so the placeholders show what to decide.
    def self.write(root, tenant: nil)
      dir = File.join(root, "enola", "recipes")
      FileUtils.mkdir_p(dir)
      RECIPES.each_with_object([]) do |name, written|
        target = File.join(dir, "#{name}.yaml")
        next if File.exist?(target)

        body = File.read(source(name))
        body = fill(body, tenant) if TEMPLATES.include?(name) && tenant
        File.write(target, body)
        written << target
      end
    end

    def self.fill(body, tenant)
      body.gsub(PLACEHOLDERS[:column], tenant.fetch(:column)).gsub(PLACEHOLDERS[:table], tenant.fetch(:table))
    end
  end
end
