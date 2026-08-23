# frozen_string_literal: true

require_relative "test_helper"

class FetcherTest < EnolaTest
  def test_fetches_verifies_and_caches_under_channel_and_version
    path = fetcher.fetch

    assert_equal File.join(@cache, "upstream", Enola::UPSTREAM_VERSION, "enola"), path
    assert File.executable?(path)
    assert File.exist?(File.join(@cache, "upstream", Enola::UPSTREAM_VERSION, "LICENSE"))
    assert fetcher.cached?
  end

  def test_refuses_a_tarball_that_does_not_match_the_published_checksum
    base = FakeRelease.build(File.join(@tmp, "bad"), platform: PLATFORM, checksum: "0" * 64)
    channel = Enola::Channel.new(name: "upstream", release_base: base, version: Enola::UPSTREAM_VERSION, asset_prefix: "enola")

    error = assert_raises(Enola::Unverified) { fetcher(channel).fetch }

    assert_match(/did not match the checksum upstream published for #{Enola::UPSTREAM_VERSION}/, error.message)
    assert_match(/nothing was installed/, error.message)
    refute fetcher(channel).cached?
  end

  def test_offline_with_an_empty_cache_is_a_refusal_that_names_cache_and_release
    error = assert_raises(Enola::Unavailable) { fetcher(unreachable).fetch }

    assert_match(%r{not in the cache at #{Regexp.escape(File.join(@cache, 'upstream', Enola::UPSTREAM_VERSION))}}, error.message)
    assert_match(%r{could not be fetched from file://}, error.message)
  end

  def test_a_cached_binary_is_not_fetched_again
    fetcher.fetch
    FileUtils.rm_rf(File.join(@tmp, "releases"))

    assert_equal fetcher.binary_path, fetcher.fetch
  end
end
