# frozen_string_literal: true

require_relative "test_helper"

class ChannelTest < Minitest::Test
  def test_upstream_names_the_release_assets_the_way_enola_labs_publishes_them
    channel = Enola::Channel::UPSTREAM

    assert_equal "https://github.com/enola-labs/enola/releases/download/v#{Enola::UPSTREAM_VERSION}/enola-#{Enola::UPSTREAM_VERSION}-linux-amd64.tar.gz",
                 channel.url(channel.asset("linux-amd64"))
    assert_equal "enola-#{Enola::UPSTREAM_VERSION}-darwin-arm64.sha256", channel.checksum_asset("darwin-arm64")
    assert_equal File.join("/c", "upstream", Enola::UPSTREAM_VERSION), channel.cache_dir("/c")
  end

  def test_the_gem_versions_itself_and_names_the_release_it_drives
    assert_match(/\A\d+\.\d+\.\d+\z/, Enola::VERSION)
    assert_match(/\A\d+\.\d+\.\d+\z/, Enola::UPSTREAM_VERSION)
    assert_equal Enola::UPSTREAM_VERSION, Enola::Channel::UPSTREAM.version
  end

  def test_another_channel_overrides_name_and_release_base_only
    channel = Enola::Channel.new(name: "other", release_base: "https://example.test/dl", version: "0.4.4.1", asset_prefix: "enola")

    assert_equal "https://example.test/dl/v0.4.4.1/enola-0.4.4.1-linux-amd64.tar.gz", channel.url(channel.asset("linux-amd64"))
    assert_equal "other 0.4.4.1", channel.to_s
  end
end
