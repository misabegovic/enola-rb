# frozen_string_literal: true

require "fileutils"
require "open3"
require "yaml"

module Munola
  class Installer
    Report = Struct.new(:written, :bound, :commented, :notes, keyword_init: true) do
      def lines
        out = written.map { |path| "wrote #{path}" }
        out << "bound #{bound.join(', ')}" unless bound.empty?
        out << "left commented, bind when the directories exist: #{commented.join(', ')}" unless commented.empty?
        out + notes
      end
    end

    def initialize(root, tenant_column: nil, binary: nil, stderr: $stderr)
      @root = File.expand_path(root)
      @tenant_column = tenant_column
      @binary = binary
      @stderr = stderr
      @report = Report.new(written: [], bound: [], commented: [], notes: [])
    end

    # The Rails layer first (starter laws, the binary's own init, upstream's
    # recipes commented), then what only munola carries: the catalogue, the
    # bindings the tree justifies, the providers both on by default.
    def install
      rails = EnolaRb::Installer.new(@root, binary: resolved_binary, stderr: @stderr).install
      @report.written.concat(rails.written)
      @report.notes.concat(rails.notes)

      detector = Detector.new(@root)
      tenant = detector.tenant(column: @tenant_column)
      values = tenant&.table ? { column: tenant.column, table: tenant.table } : nil
      @report.written.concat(Catalogue.write(@root, tenant: values).map { |p| relative(p) })
      bind(detector.bindings + (tenant&.table ? ["tenant-foreign-key"] : []))
      note_tenant(tenant)
      providers
      @report.bound = (rails.bound + @bound).uniq
      @report.commented = rails.unbound + @commented
      @report
    end

    private

    def resolved_binary
      @binary ||= Munola.resolve.path
    rescue Enola::Error
      nil
    end

    def bindings_path
      File.join(@root, "enola", "constraints", "recipes.yaml")
    end

    def bind(names)
      @bound = names & Catalogue::RECIPES
      @commented = Catalogue::RECIPES - @bound
      existing = File.exist?(bindings_path) ? File.read(bindings_path) : "use_recipe: []\n"
      return if existing.include?("# munola catalogue")

      doc = YAML.safe_load(existing) || {}
      entries = Array(doc["use_recipe"]) + @bound.map { |name| { "recipe" => name, "as" => name, "mode" => "advisory" } }
      body = YAML.dump({ "use_recipe" => entries }).sub(/\A---\n/, "")
      tail = existing[/\n# Shipped recipes not bound.*\z/m].to_s
      commented = @commented.map { |name| "#  - recipe: #{name}\n#    as: #{name}\n#    mode: advisory\n" }.join
      File.write(bindings_path, "#{body}#{tail}\n# munola catalogue recipes not bound because the tree shows no need for them yet.\n" \
                                "# Uncomment one to switch it on, then run `enola constraints lint`.\n#{commented}")
      @report.written << relative(bindings_path) unless @report.written.include?(relative(bindings_path))
    end

    def note_tenant(tenant)
      if tenant&.table
        note("tenant column #{tenant.column} on #{(tenant.share * 100).round}% of tables, referencing #{tenant.table}; tenant-foreign-key written with it")
      elsif tenant && tenant.share.zero?
        note("#{tenant.column} appears on no table in db/schema.rb; tenant-foreign-key keeps its placeholders")
      elsif tenant
        note("tenant column #{tenant.column} found but no table named for it in the schema; tenant-foreign-key keeps its TENANT_TABLE placeholder")
      elsif @tenant_column
        note("#{@tenant_column} appears on no table in db/schema.rb; tenant-foreign-key keeps its placeholders")
      else
        note("no column sits on most tables; tenant-foreign-key keeps its placeholders, pass --tenant-column to name one")
      end
    end

    def providers
      path = ProvidersConfig.write(@root)
      if path
        @report.written << relative(path)
        note("prism provider: the enola gem carries no provider script yet; mcp-arch.yaml names the slot") unless ProvidersConfig.prism_script
      end
      binary = resolved_binary
      note(binary ? ProvidersConfig.fetch_rubydex(binary) : "rubydex library not fetched: no binary resolved; run `enola providers fetch rubydex` once it is")
    end

    def relative(path)
      path.delete_prefix("#{@root}/")
    end

    def note(text)
      @report.notes << text
      @stderr.puts "munola: #{text}"
    end
  end
end
