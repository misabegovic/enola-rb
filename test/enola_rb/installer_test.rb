# frozen_string_literal: true

require_relative "../test_helper"
require "enola-rb"
require "stringio"

class EnolaRbInstallerTest < EnolaTest
  GUIDES = File.expand_path("../fixtures/guides", __dir__)

  INIT_STUB = <<~SH
    #!/bin/sh
    if [ "$1" = "constraints" ] && [ "$2" = "init" ]; then
      mkdir -p "$3/enola/constraints"
      if [ -e "$3/enola/constraints/recipes.yaml" ]; then echo "refusing to overwrite"; exit 1; fi
      printf 'use_recipe:\\n  - recipe: rails-conventions\\n    as: rails\\n' > "$3/enola/constraints/recipes.yaml"
      echo 'unknown command "constraints"'
      exit 1
    fi
    echo "enola version #{Enola::UPSTREAM_VERSION}"
  SH

  def setup
    super
    ENV["ENOLA_GUIDES_DIR"] = GUIDES
    @app = File.join(@tmp, "app")
    FileUtils.mkdir_p(File.join(@app, "app", "models"))
    File.write(File.join(@app, ".gitignore"), "/log\n")
    @stub = File.join(@tmp, "stub-enola")
    File.write(@stub, INIT_STUB)
    FileUtils.chmod(0o755, @stub)
  end

  def teardown
    ENV.delete("ENOLA_GUIDES_DIR")
    super
  end

  def install(binary: @stub)
    EnolaRb::Installer.new(@app, binary: binary, stderr: StringIO.new).install
  end

  def test_writes_the_provider_config_before_anything_else
    report = install

    assert_equal "mcp-arch.yaml", report.written.first
    assert_match(/name: prism/, File.read(File.join(@app, "mcp-arch.yaml")))
  end

  def test_the_config_pins_the_rubydex_version_the_binary_lists
    File.write(@stub, INIT_STUB.sub("#!/bin/sh\n", "#!/bin/sh\n[ \"$1\" = providers ] && [ \"$2\" = list ] && { echo '  rubydex  9.9.9 at /nowhere'; exit 0; }\n"))
    install

    config = YAML.safe_load(File.read(File.join(@app, "mcp-arch.yaml")))
    assert_equal "9.9.9", config["providers"][1]["expected_version"]
  end

  LAYERED = "use_recipe:\n  - recipe: layered\n    as: layered\n    bind:\n      presentation: { match: [\"app/controllers/**\"] }\n      " \
            "application: { match: [\"app/jobs/**\"] }\n  - recipe: ruby-conventions\n    as: ruby-conventions\n"

  def stub_init_writing(bindings)
    source = File.join(@tmp, "init-wrote.yaml")
    File.write(source, bindings)
    File.write(@stub, INIT_STUB.sub(/printf '[^']*' >/, "cp #{source}"))
  end

  def test_layered_is_bound_advisory_so_a_controller_calling_a_model_fails_nothing
    stub_init_writing(LAYERED)
    report = install

    doc = YAML.safe_load(File.read(File.join(@app, "enola", "constraints", "recipes.yaml")))
    layered = doc["use_recipe"].find { |entry| entry["recipe"] == "layered" }
    assert_equal "advisory", layered["mode"]
    assert_equal({ "match" => ["app/jobs/**"] }, layered["bind"]["application"])
    refute doc["use_recipe"].find { |entry| entry["recipe"] == "ruby-conventions" }.key?("mode")
    assert report.notes.any? { |n| n.include?("layered bound advisory") }, report.notes.inspect
  end

  def test_a_recipes_file_the_app_already_had_is_left_alone
    FileUtils.mkdir_p(File.join(@app, "enola", "constraints"))
    File.write(File.join(@app, "enola", "constraints", "recipes.yaml"), LAYERED)
    install

    refute_match(/mode: advisory/, File.read(File.join(@app, "enola", "constraints", "recipes.yaml")))
  end

  def test_writes_the_starter_laws_and_ignores_the_artifacts
    report = install

    assert File.exist?(File.join(@app, "enola", "constraints", "models-do-not-reach-controllers.rb"))
    assert_includes report.written, "enola/constraints/models-do-not-reach-controllers.rb"
    assert_includes File.read(File.join(@app, ".gitignore")), ".enola/"
  end

  def test_reads_what_init_wrote_rather_than_its_exit_code
    report = install

    assert_equal ["rails-conventions"], report.bound
    assert_empty report.notes.grep(/constraints init/)
  end

  def test_every_unbound_built_in_recipe_is_written_as_a_commented_binding
    report = install
    bindings = File.read(File.join(@app, "enola", "constraints", "recipes.yaml"))

    assert_includes report.unbound, "rails-strict"
    refute_includes report.unbound, "rails-conventions"
    assert_match(/^#  - recipe: rails-strict$/, bindings)
    assert_match(/^  - recipe: rails-conventions$/, bindings)
  end

  def test_a_second_run_writes_nothing_twice
    install
    report = install

    assert_empty report.written
    assert_equal 1, File.read(File.join(@app, "enola", "constraints", "recipes.yaml")).scan("Shipped recipes not bound").size
  end

  # The resolver is replaced as well as the channel: whichever channel's gem is
  # loaded installs its own factory, and that factory would reach its own
  # releases over the network rather than the unreachable one named here.
  def test_an_absent_binary_still_writes_the_laws_and_says_so
    ENV["ENOLA_CACHE_DIR"] = File.join(@tmp, "empty-cache")
    channel_before = Enola.channel
    factory_before = Enola.resolver_factory
    Enola.channel = unreachable
    Enola.resolver_factory = -> { resolver(channel: unreachable) }
    report = install(binary: nil)

    assert File.exist?(File.join(@app, "enola", "constraints", "models-do-not-reach-controllers.rb"))
    assert report.notes.any? { |note| note.include?("absent") }, report.notes.inspect
  ensure
    Enola.channel = channel_before
    Enola.resolver_factory = factory_before
    ENV.delete("ENOLA_CACHE_DIR")
  end

  def test_a_missing_guides_gem_is_a_refusal_naming_the_gemfile_line
    ENV.delete("ENOLA_GUIDES_DIR")
    missing = ->(*) { raise Gem::MissingSpecError.new("enola-guides", nil) }
    error = Gem::Specification.stub(:find_by_name, missing) { assert_raises(Enola::Unavailable) { install } }

    assert_includes error.message, 'gem "enola-guides"'
  end

  def test_refuses_outside_a_rails_root
    FileUtils.rm_rf(File.join(@app, "app"))
    error = assert_raises(Enola::Unavailable) { install }

    assert_includes error.message, "app/"
  end
end
