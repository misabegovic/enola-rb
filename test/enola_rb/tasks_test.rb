# frozen_string_literal: true

require_relative "../test_helper"
require "enola-rb"
require "rake"

class TasksTest < EnolaTest
  def setup
    super
    @rake_before = Rake.application
    @rake = Rake::Application.new
    Rake.application = @rake
    Rake::TaskManager.record_task_metadata = true
    if defined?(Rails)
      @rails_before = [Rails.app_class, Rails.application]
      Rails.app_class = nil
      Rails.application = nil
    end
    load EnolaRb::TASKS
  end

  def teardown
    Rake.application = @rake_before
    Rails.app_class, Rails.application = @rails_before if defined?(Rails)
    super
  end

  def test_defines_the_three_tasks_with_descriptions
    assert_equal %w[enola:check enola:init enola:snapshot], @rake.tasks.map(&:name).sort
    assert @rake.tasks.all? { |task| task.comment.to_s.length > 10 }
  end

  def with_runner(stub)
    Enola::Runner.class_eval do
      alias_method :run_before_stub, :run
      define_method(:run, &stub)
    end
    yield
  ensure
    Enola::Runner.class_eval do
      alias_method :run, :run_before_stub
      remove_method :run_before_stub
    end
  end

  def test_snapshot_forwards_generate_then_pin_to_the_wrapper
    seen = []
    with_runner(->(argv) { seen << argv; 0 }) do
      Dir.chdir(@tmp) { @rake["enola:snapshot"].invoke }
    end

    root = File.realpath(@tmp)

    assert_equal [["--generate", root], ["baseline", "pin", root]], seen
  end

  def test_check_aborts_with_the_wrapper_exit_code_when_it_fails
    error = with_runner(->(_argv) { 1 }) do
      assert_raises(SystemExit) { Dir.chdir(@tmp) { @rake["enola:check"].invoke } }
    end

    assert_equal 1, error.status
  end
end
