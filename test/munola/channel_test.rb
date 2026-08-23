# frozen_string_literal: true

require_relative "../test_helper"
require "munola"

class MunolaChannelTest < EnolaTest
  def test_the_channel_is_the_fork_at_the_munola_tag
    assert_equal "munola", Munola::CHANNEL.name
    assert_equal Munola::CHANNEL_VERSION, Munola::CHANNEL.version
    assert_equal "munola-v#{Munola::CHANNEL_VERSION}", Munola::CHANNEL.tag
    assert_equal "https://github.com/misabegovic/enola/releases/download/munola-v#{Munola::CHANNEL_VERSION}/enola-#{Munola::CHANNEL_VERSION}-linux-amd64.tar.gz",
                 Munola::CHANNEL.url(Munola::CHANNEL.asset("linux-amd64"))
    assert_equal Munola::CHANNEL, Enola.channel
  end

  def test_the_gem_versions_itself_and_names_what_it_drives
    assert_match(/\A\d+\.\d+\.\d+\z/, Munola::VERSION)
    assert_match(/\A#{Regexp.escape(Munola::UPSTREAM_VERSION)}\.\d+\z/, Munola::CHANNEL_VERSION)
    assert_equal Enola::UPSTREAM_VERSION, Munola::UPSTREAM_VERSION
  end

  def test_a_release_at_the_munola_tag_is_fetched_and_verified
    base = FakeRelease.build(File.join(@tmp, "fork"), platform: PLATFORM, version: Munola::CHANNEL_VERSION)
    FileUtils.mv(File.join(@tmp, "fork", "v#{Munola::CHANNEL_VERSION}"), File.join(@tmp, "fork", "munola-v#{Munola::CHANNEL_VERSION}"))
    channel = Enola::Channel.new(name: "munola", release_base: base, version: Munola::CHANNEL_VERSION, asset_prefix: "enola", tag_prefix: "munola-v")

    found = Munola::Resolver.new(override: nil, channel: channel, cache_root: @cache, platform: PLATFORM, path: "").resolve

    assert_equal "fetched", found.source
    assert_equal File.join(@cache, "munola", Munola::CHANNEL_VERSION, "enola"), found.path
    assert_equal "enola version #{Munola::CHANNEL_VERSION}", `#{found.path} --version`.strip
  end

  def test_the_override_names_the_binary_it_drives
    binary = FakeRelease.binary(File.join(@tmp, "dev"), Enola::UPSTREAM_VERSION)

    found = Munola::Resolver.new(override: binary, channel: Munola::CHANNEL, cache_root: @cache, platform: PLATFORM, path: "").resolve

    assert_equal binary, found.path
    assert_match(/MUNOLA_BINARY \(#{Enola::UPSTREAM_VERSION}\)/, found.source)
    assert_match(/munola #{Regexp.escape(Munola::VERSION)}, channel #{Regexp.escape(Munola::CHANNEL_VERSION)} on enola #{Regexp.escape(Munola::UPSTREAM_VERSION)}; binary via MUNOLA_BINARY/,
                 Munola.channel_line(found))
  end

  def test_the_override_must_be_executable
    error = assert_raises(Enola::Unavailable) do
      Munola::Resolver.new(override: File.join(@tmp, "nope"), channel: Munola::CHANNEL, cache_root: @cache, platform: PLATFORM, path: "").resolve
    end
    assert_match(/MUNOLA_BINARY names .*nope, which is not executable/, error.message)
  end

  def test_offline_with_an_empty_cache_refuses_by_name
    channel = Enola::Channel.new(name: "munola", release_base: "file://#{@tmp}/missing", version: Munola::CHANNEL_VERSION, asset_prefix: "enola", tag_prefix: "munola-v")
    error = assert_raises(Enola::Unavailable) do
      Munola::Resolver.new(override: nil, channel: channel, cache_root: @cache, platform: PLATFORM, path: "").resolve
    end
    assert_match(/enola munola #{Regexp.escape(Munola::CHANNEL_VERSION)} is not in the cache/, error.message)
  end
end
