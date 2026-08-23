# frozen_string_literal: true

require_relative "../test_helper"
require "rails"
require "rails/generators"
require "munola-rb"
require "yaml"

class MunolaRbGeneratorTest < EnolaTest
  GUIDES = File.expand_path("../fixtures/guides", __dir__)

  STUB = <<~SH
    #!/bin/sh
    if [ "$1" = "constraints" ] && [ "$2" = "init" ]; then
      mkdir -p "$3/enola/constraints"
      [ -e "$3/enola/constraints/recipes.yaml" ] || printf 'use_recipe:\\n  - recipe: rails-conventions\\n    as: rails\\n' > "$3/enola/constraints/recipes.yaml"
      exit 0
    fi
    if [ "$1" = "providers" ] && [ "$2" = "fetch" ]; then echo "rubydex 0.4.0 installed"; exit 0; fi
    echo "enola version #{Enola::VERSION}"
  SH

  SCHEMA = <<~RUBY
    ActiveRecord::Schema[8.1].define(version: 1) do
      create_table "companies", force: :cascade do |t|
        t.string "name"
      end
      create_table "jobs", force: :cascade do |t|
        t.bigint "company_id"
      end
    end
  RUBY

  def setup
    super
    ENV["ENOLA_GUIDES_DIR"] = GUIDES
    @app = File.join(@tmp, "app-root")
    FileUtils.mkdir_p(File.join(@app, "app", "models"))
    FileUtils.mkdir_p(File.join(@app, "app", "policies"))
    FileUtils.mkdir_p(File.join(@app, "config"))
    FileUtils.mkdir_p(File.join(@app, "db"))
    File.write(File.join(@app, "config", "routes.rb"), "Rails.application.routes.draw {}\n")
    File.write(File.join(@app, "db", "schema.rb"), SCHEMA)
    @stub = File.join(@tmp, "stub-enola")
    File.write(@stub, STUB)
    FileUtils.chmod(0o755, @stub)
    @installed = Enola.channel
    Enola.resolver_factory = -> { StubResolver.new(@stub) }
  end

  def teardown
    ENV.delete("ENOLA_GUIDES_DIR")
    Enola.channel = @installed
    Enola.resolver_factory = -> { Munola::Resolver.new(channel: Munola::CHANNEL) }
    super
  end

  class StubResolver
    Found = Struct.new(:path, :source)

    def initialize(path)
      @path = path
    end

    def resolve
      Found.new(@path, "stub")
    end
  end

  def run_generator(args = [])
    require "munola/../generators/munola/install/install_generator"
    generator = Munola::Generators::InstallGenerator.new([], args, destination_root: @app)
    generator.instance_variable_set(:@shell, Thor::Shell::Basic.new)
    capture_io { generator.invoke_all }
  end

  def test_the_generator_writes_the_laws_the_bindings_and_the_catalogue
    run_generator(["--tenant-column", "company_id"])

    assert File.exist?(File.join(@app, "enola", "constraints", "models-do-not-reach-controllers.rb"))
    assert File.exist?(File.join(@app, "enola", "recipes", "data-ownership.yaml"))
    assert File.exist?(File.join(@app, "mcp-arch.yaml"))
    bound = YAML.safe_load(File.read(File.join(@app, "enola", "constraints", "recipes.yaml")))["use_recipe"].map { |e| e["recipe"] }
    assert_includes bound, "data-ownership"
    assert_includes bound, "api-boundaries"
    refute_includes File.read(File.join(@app, "enola", "recipes", "tenant-foreign-key.yaml")), "TENANT_COLUMN"
  end
end
