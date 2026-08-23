# frozen_string_literal: true

require_relative "../test_helper"
require "rails"
require "rails/generators"
require "enola-rb"

class RailtieTest < EnolaTest
  def test_the_railtie_loads_the_tasks_and_the_generator_into_a_rails_app
    Rake.application = Rake::Application.new
    app = Class.new(Rails::Application) { config.eager_load = false }
    app.instance.load_tasks
    generator = Rails::Generators.find_by_namespace("install", "enola")

    assert Rake.application.lookup("enola:check")
    assert_equal "Enola::Generators::InstallGenerator", generator.name
  end
end
