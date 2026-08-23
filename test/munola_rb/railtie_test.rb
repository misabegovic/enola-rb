# frozen_string_literal: true

require_relative "../test_helper"
require "rails"
require "rails/generators"
require "munola-rb"

class MunolaRbRailtieTest < EnolaTest
  def test_the_railtie_loads_the_generator_and_the_tasks_that_come_with_enola_rb
    Rake.application = Rake::Application.new
    app = Class.new(Rails::Application) { config.eager_load = false }
    app.instance.load_tasks
    generator = Rails::Generators.find_by_namespace("install", "munola")

    assert Rake.application.lookup("enola:check")
    assert_equal "Munola::Generators::InstallGenerator", generator.name
  end

  def test_the_version_follows_munola
    assert_equal Munola::VERSION, MunolaRb::VERSION
  end

  # The rake tasks are enola-rb's and drive whatever resolver is installed;
  # loading this gem must leave munola's in place, or a Rails app on this
  # channel would snapshot with the upstream binary.
  def test_the_installed_resolver_is_munolas
    assert_equal Munola::CHANNEL, Enola.channel
    assert_instance_of Munola::Resolver, Enola.resolver
  end
end
