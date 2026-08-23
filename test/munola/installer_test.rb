# frozen_string_literal: true

require_relative "../test_helper"
require "munola"
require "stringio"
require "yaml"

class MunolaInstallerTest < EnolaTest
  GUIDES = File.expand_path("../fixtures/guides", __dir__)

  STUB = <<~SH
    #!/bin/sh
    if [ "$1" = "constraints" ] && [ "$2" = "init" ]; then
      mkdir -p "$3/enola/constraints"
      [ -e "$3/enola/constraints/recipes.yaml" ] || printf 'use_recipe:\\n  - recipe: rails-conventions\\n    as: rails\\n' > "$3/enola/constraints/recipes.yaml"
      echo 'unknown command "constraints"'
      exit 1
    fi
    if [ "$1" = "providers" ] && [ "$2" = "fetch" ]; then echo "rubydex 0.4.0 installed at $HOME/.cache"; exit "${FETCH_EXIT:-0}"; fi
    echo "enola version #{Enola::UPSTREAM_VERSION}"
  SH

  SCHEMA = <<~RUBY
    ActiveRecord::Schema[8.1].define(version: 1) do
      create_table "companies", force: :cascade do |t|
        t.string "name"
      end
      create_table "jobs", force: :cascade do |t|
        t.bigint "company_id"
        t.string "title"
      end
      create_table "candidates", force: :cascade do |t|
        t.bigint "company_id"
        t.string "email"
      end
      create_table "schema_migrations", force: :cascade do |t|
        t.string "version"
      end
    end
  RUBY

  def setup
    super
    ENV["ENOLA_GUIDES_DIR"] = GUIDES
    @app = File.join(@tmp, "app")
    FileUtils.mkdir_p(File.join(@app, "app", "models"))
    @stub = File.join(@tmp, "stub-enola")
    File.write(@stub, STUB)
    FileUtils.chmod(0o755, @stub)
  end

  def teardown
    ENV.delete("ENOLA_GUIDES_DIR")
    super
  end

  def rails_app(policies: true, tasks: true, ember: false, schema: true)
    FileUtils.mkdir_p(File.join(@app, "config"))
    File.write(File.join(@app, "config", "routes.rb"), "Rails.application.routes.draw {}\n")
    FileUtils.mkdir_p(File.join(@app, "app", "policies")) if policies
    FileUtils.mkdir_p(File.join(@app, "app", "tasks")) if tasks
    File.write(File.join(@app, "ember-cli-build.js"), "module.exports = {}\n") if ember
    if schema
      FileUtils.mkdir_p(File.join(@app, "db"))
      File.write(File.join(@app, "db", "schema.rb"), SCHEMA)
    end
  end

  def install(tenant_column: nil)
    Munola::Installer.new(@app, tenant_column: tenant_column, binary: @stub, stderr: StringIO.new).install
  end

  def bindings
    YAML.safe_load(File.read(File.join(@app, "enola", "constraints", "recipes.yaml")))["use_recipe"].map { |e| e["recipe"] }
  end

  def recipe(name)
    File.read(File.join(@app, "enola", "recipes", "#{name}.yaml"))
  end

  def test_writes_the_catalogue_beside_the_starter_laws
    rails_app
    report = install

    Munola::Catalogue::RECIPES.each { |name| assert File.exist?(File.join(@app, "enola", "recipes", "#{name}.yaml")), name }
    assert File.exist?(File.join(@app, "enola", "constraints", "models-do-not-reach-controllers.rb"))
    assert_includes report.written, "enola/recipes/data-ownership.yaml"
  end

  def test_binds_what_the_tree_shows_and_comments_the_rest
    rails_app(ember: false)
    report = install

    assert_equal %w[rails-conventions data-ownership api-boundaries background-work tenant-foreign-key], bindings
    assert_includes report.commented, "ember-conventions"
    text = File.read(File.join(@app, "enola", "constraints", "recipes.yaml"))
    assert_includes text, "#  - recipe: ember-conventions"
    assert_includes text, "# munola catalogue"
  end

  def test_detects_ember_and_the_absence_of_policies
    rails_app(policies: false, tasks: false, ember: true)
    install

    assert_equal %w[rails-conventions ember-conventions data-ownership tenant-foreign-key], bindings
  end

  def test_the_tenant_column_is_the_one_most_tables_share_and_its_table_comes_from_the_schema
    rails_app
    report = install

    assert_includes recipe("tenant-foreign-key"), "company_id->companies"
    refute_includes recipe("tenant-foreign-key"), "TENANT_COLUMN"
    assert report.notes.any? { |n| n.include?("company_id on 50% of tables, referencing companies") }, report.notes.inspect
  end

  def test_a_named_column_absent_from_the_schema_keeps_the_placeholders
    rails_app
    report = install(tenant_column: "account_id")

    assert_includes recipe("tenant-foreign-key"), "TENANT_COLUMN"
    refute_includes bindings, "tenant-foreign-key"
    assert report.notes.any? { |n| n.include?("account_id appears on no table") }
  end

  def test_without_a_schema_nothing_is_guessed
    rails_app(schema: false)
    report = install

    assert_includes recipe("tenant-foreign-key"), "TENANT_TABLE"
    refute_includes bindings, "data-ownership"
    assert report.notes.any? { |n| n.include?("no column sits on most tables") }
  end

  def test_existing_recipe_files_are_never_overwritten
    rails_app
    FileUtils.mkdir_p(File.join(@app, "enola", "recipes"))
    File.write(File.join(@app, "enola", "recipes", "data-ownership.yaml"), "recipe: data-ownership\nroles: []\nrules: []\n")
    install

    assert_equal "recipe: data-ownership\nroles: []\nrules: []\n", recipe("data-ownership")
  end

  def test_is_idempotent
    rails_app
    install
    before = File.read(File.join(@app, "enola", "constraints", "recipes.yaml"))
    install

    assert_equal before, File.read(File.join(@app, "enola", "constraints", "recipes.yaml"))
  end

  def test_both_providers_are_on_by_default_and_rubydex_is_fetched
    rails_app
    report = install

    config = File.read(File.join(@app, "mcp-arch.yaml"))
    assert_includes config, "name: rubydex"
    assert_includes config, "expected_version: \"0.4.0\""
    assert_includes config, "prism"
    assert report.notes.any? { |n| n.include?("rubydex 0.4.0 library in place") }, report.notes.inspect
  end

  def test_a_failed_rubydex_fetch_is_a_named_skip
    rails_app
    ENV["FETCH_EXIT"] = "1"
    report = install

    assert report.notes.any? { |n| n.include?("rubydex library not fetched") && n.include?("named skip") }, report.notes.inspect
  ensure
    ENV.delete("FETCH_EXIT")
  end

  def test_an_existing_providers_config_is_left_alone
    rails_app
    File.write(File.join(@app, "mcp-arch.yaml"), "repos: [.]\n")
    install

    assert_equal "repos: [.]\n", File.read(File.join(@app, "mcp-arch.yaml"))
  end

  def test_a_missing_guides_recipe_names_the_version_needed
    rails_app
    ENV["ENOLA_GUIDES_DIR"] = File.join(@tmp, "old-guides")
    FileUtils.mkdir_p(File.join(@tmp, "old-guides", "templates", "constraints-starter"))
    FileUtils.mkdir_p(File.join(@tmp, "old-guides", "recipes"))

    error = assert_raises(Enola::Unavailable) { install }
    assert_match(/no recipe ember-conventions; it needs 0\.3\.1 or later/, error.message)
  end
  # A munola binary carries the catalogue, so its own init may bind a recipe
  # the installer would bind again; two instances of one recipe expand to
  # colliding rule ids, which the snapshot refuses.
  def test_a_recipe_the_binary_already_bound_is_not_bound_twice
    rails_app
    FileUtils.mkdir_p(File.join(@app, "enola", "constraints"))
    File.write(File.join(@app, "enola", "constraints", "recipes.yaml"),
               "use_recipe:\n  - recipe: rails-conventions\n    as: rails\n  - recipe: data-ownership\n    as: data-ownership\n")
    report = install

    assert_equal 1, bindings.count("data-ownership")
    assert_includes report.bound, "data-ownership"
  end

end
