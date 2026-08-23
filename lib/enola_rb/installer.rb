# frozen_string_literal: true

require "fileutils"
require "open3"
require "yaml"

module EnolaRb
  class Installer
    Report = Struct.new(:written, :bound, :unbound, :notes, keyword_init: true) do
      def lines
        out = written.map { |path| "wrote #{path}" }
        out << "bound #{bound.join(', ')}" unless bound.empty?
        out << "left commented, bind when the directories exist: #{unbound.join(', ')}" unless unbound.empty?
        out + notes
      end
    end

    def initialize(root, binary: nil, stderr: $stderr)
      @root = File.expand_path(root)
      @binary = binary
      @stderr = stderr
      @report = Report.new(written: [], bound: [], unbound: [], notes: [])
    end

    def install
      raise Enola::Unavailable, "#{@root} holds no app/ directory; run this from the Rails root" unless File.directory?(File.join(@root, "app"))

      copy_starter_laws
      init_with_binary
      comment_unbound
      ignore_artifacts
      @report
    end

    private

    def constraints_dir
      File.join(@root, "enola", "constraints")
    end

    def bindings_path
      File.join(constraints_dir, "recipes.yaml")
    end

    def copy_starter_laws
      FileUtils.mkdir_p(constraints_dir)
      Guides.starter_laws.each do |law|
        target = File.join(constraints_dir, File.basename(law))
        next if File.exist?(target)

        FileUtils.cp(law, target)
        @report.written << relative(target)
      end
    end

    # The binary's own `constraints init` decides what binds; what it wrote is
    # read rather than its exit code, because the release that shipped the
    # surface exits through its unknown-command line after doing the work.
    def init_with_binary
      binary = @binary || Surface.require!(:constraints, binary: Enola::Resolver.new.resolve.path)
      out, status = Open3.capture2e(binary, "constraints", "init", @root)
      note("constraints init: #{out.lines.last&.strip}") unless status.success? || File.exist?(bindings_path)
    rescue Enola::Error => e
      note("the enola binary is absent (#{e.message}); the laws are written, run `rake enola:init` once it can be fetched")
    end

    def bound
      return [] unless File.exist?(bindings_path)

      Array((YAML.safe_load(File.read(bindings_path)) || {})["use_recipe"]).map { |entry| entry["recipe"] }.compact
    end

    def comment_unbound
      @report.bound = bound
      @report.unbound = Guides::BUILT_IN_RECIPES - @report.bound
      return if @report.unbound.empty?

      existing = File.exist?(bindings_path) ? File.read(bindings_path) : "use_recipe: []\n"
      return if existing.include?("# Shipped recipes not bound")

      commented = @report.unbound.map { |name| "#  - recipe: #{name}\n#    as: #{name}\n#    mode: ratchet\n" }.join
      File.write(bindings_path, "#{existing.chomp}\n\n# Shipped recipes not bound because their roles found no directory here.\n# Uncomment one once the directories exist, then run `enola constraints lint`.\n#{commented}")
      @report.written << relative(bindings_path)
    end

    def ignore_artifacts
      path = File.join(@root, ".gitignore")
      existing = File.exist?(path) ? File.read(path) : ""
      return if existing.lines.any? { |line| line.strip == ".enola/" }

      File.write(path, "#{existing.chomp}\n.enola/\n".lstrip)
      @report.written << ".gitignore"
    end

    def relative(path)
      path.delete_prefix("#{@root}/")
    end

    def note(text)
      @report.notes << text
      @stderr.puts "enola: #{text}"
    end
  end
end
