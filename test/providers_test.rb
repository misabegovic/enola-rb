# frozen_string_literal: true

require_relative "test_helper"
require "stringio"

class ProvidersTest < EnolaTest
  def test_the_vendored_prism_script_answers_its_version_under_this_ruby
    assert_match(/\A\d+\.\d+\.\d+\z/, Enola::Providers.prism_version)
    assert File.executable?(Enola::Providers.prism_script)
  end

  def test_rubydex_expected_version_is_read_from_the_binary_when_it_lists_one
    assert_equal "0.4.0", Enola::Providers.rubydex_expected_version(fetcher.fetch)
    assert_equal Enola::Providers::RUBYDEX_EXPECTED_VERSION, Enola::Providers.rubydex_expected_version(nil)
  end

  def test_the_engine_is_fetched_once_per_version_and_remembered
    binary = fetcher.fetch
    stderr = StringIO.new

    first = Enola::Providers.ensure_rubydex(binary, channel: @channel, cache_root: @cache, stderr: stderr)
    File.write(binary, "#!/bin/sh\nexit 9\n")
    second = Enola::Providers.ensure_rubydex(binary, channel: @channel, cache_root: @cache, stderr: stderr)

    assert_equal "fetched", first
    assert_equal "fetched", second
    assert_empty stderr.string
  end

  def test_a_failed_fetch_is_a_named_skip_printed_once
    binary = fetcher.fetch
    File.write(binary, "#!/bin/sh\necho 'no network'; exit 1\n")
    stderr = StringIO.new

    outcome = Enola::Providers.ensure_rubydex(binary, channel: @channel, cache_root: @cache, stderr: stderr)
    Enola::Providers.ensure_rubydex(binary, channel: @channel, cache_root: @cache, stderr: stderr)

    assert_equal "skipped: no network", outcome
    assert_equal 1, stderr.string.scan("named skip").size
  end

  def test_the_runner_ensures_the_engine_before_forwarding
    stderr = StringIO.new
    runner = Enola::Runner.new(resolver: resolver, channel: @channel, stderr: stderr)

    Enola.stub(:cache_root, @cache) { runner.command(["--version"]) }

    assert_equal "fetched", File.read(File.join(@channel.cache_dir(@cache), "providers-rubydex")).strip
  end
end
