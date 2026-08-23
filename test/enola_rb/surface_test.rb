# frozen_string_literal: true

require_relative "../test_helper"
require "enola-rb"

class SurfaceTest < EnolaTest
  def test_a_present_surface_returns_the_binary
    binary = FakeRelease.binary(File.join(@tmp, "bin"), Enola::UPSTREAM_VERSION)

    assert_equal binary, EnolaRb::Surface.require!(:constraints, binary: binary, channel: @channel)
  end

  def test_a_missing_surface_is_refused_by_name_with_the_channel_remedy
    binary = FakeRelease.binary(File.join(@tmp, "bin"), Enola::UPSTREAM_VERSION)
    error = assert_raises(Enola::Unavailable) { EnolaRb::Surface.require!(:hook, binary: binary, channel: @channel) }

    assert_includes error.message, "no `hook` surface"
    assert_includes error.message, "munola"
  end
end
