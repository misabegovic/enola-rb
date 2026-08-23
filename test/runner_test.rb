# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class RunnerTest < EnolaTest
  def test_forwards_arguments_and_the_exit_code_unchanged
    fetcher.fetch
    runner = Enola::Runner.new(resolver: resolver, channel: @channel, stderr: StringIO.new)

    assert_equal 3, runner.run(["fail"])
    assert_equal 0, runner.run(["echo", "--json", "a b"])
  end

  def test_verbose_names_channel_version_and_source_on_stderr
    fetcher.fetch
    err = StringIO.new
    Enola::Runner.new(resolver: resolver, channel: @channel, stderr: err).run(["echo", "--verbose"])

    assert_equal "enola: upstream #{Enola::VERSION} via cache (#{fetcher.binary_path})", err.string.lines.first.chomp
  end

  def test_without_verbose_nothing_is_added_to_stderr
    fetcher.fetch
    err = StringIO.new
    Enola::Runner.new(resolver: resolver, channel: @channel, stderr: err).run(["echo"])

    assert_empty err.string
  end
end
