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
    echo "enola version #{Enola::VERSION}"
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

  def test_an_absent_binary_still_writes_the_laws_and_says_so
    ENV["ENOLA_CACHE_DIR"] = File.join(@tmp, "empty-cache")
    Enola.channel = unreachable
    report = install(binary: nil)

    assert File.exist?(File.join(@app, "enola", "constraints", "models-do-not-reach-controllers.rb"))
    assert report.notes.any? { |note| note.include?("absent") }, report.notes.inspect
  ensure
    Enola.channel = Enola::Channel::UPSTREAM
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
