# frozen_string_literal: true

module Munola
  # Reads the tree for what the binary's own init cannot see: which catalogue
  # recipes have the directories their roles need, and which column most
  # tables share. It reads files; it never asks.
  class Detector
    Tenant = Struct.new(:column, :table, :share, keyword_init: true)

    def initialize(root)
      @root = File.expand_path(root)
    end

    def bindings
      found = []
      found << "ember-conventions" if file?("ember-cli-build.js")
      found << "data-ownership" if schema? && dir?("app/models")
      found << "api-boundaries" if file?("config/routes.rb") && dir?("app/policies")
      found << "background-work" if dir?("app/tasks")
      found
    end

    def schema?
      file?("db/schema.rb") || file?("db/structure.sql")
    end

    # The tenant column is the one present on most tables; a column the
    # caller names is confirmed against the schema rather than trusted.
    def tenant(column: nil)
      tables = schema_tables
      return nil if tables.empty?

      counts = Hash.new(0)
      tables.each_value { |columns| columns.uniq.each { |name| counts[name] += 1 } }
      candidate = column || counts.select { |name, _| name.end_with?("_id") }.max_by { |name, count| [count, -name.length] }&.first
      return nil unless candidate

      share = counts.fetch(candidate, 0).fdiv(tables.size)
      return nil if share < 0.5 && column.nil?

      table = tenant_table(candidate, tables.keys)
      Tenant.new(column: candidate, table: table, share: share)
    end

    private

    def file?(rel)
      File.file?(File.join(@root, rel))
    end

    def dir?(rel)
      File.directory?(File.join(@root, rel))
    end

    def schema_tables
      path = File.join(@root, "db", "schema.rb")
      return {} unless File.file?(path)

      tables = {}
      current = nil
      File.foreach(path) do |line|
        if (m = line.match(/create_table\s+"([^"]+)"/))
          current = m[1]
          tables[current] = []
        elsif current && (m = line.match(/^\s*t\.\w+\s+"([^"]+)"/))
          tables[current] << m[1]
        elsif line.strip == "end"
          current = nil
        end
      end
      tables
    end

    # company_id names companies, category_id names categories, person_id
    # names people only if the schema has that table: the table is looked up
    # among the schema's own names, never guessed from an inflection table.
    def tenant_table(column, names)
      stem = column.delete_suffix("_id")
      candidates = [stem, "#{stem}s", "#{stem}es", stem.sub(/y\z/, "ies")]
      names.find { |name| candidates.include?(name) }
    end
  end
end
