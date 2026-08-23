# frozen_string_literal: true

require_relative "test_helper"

class PlatformTest < Minitest::Test
  def test_maps_ruby_host_names_to_release_names
    assert_equal "linux-amd64", Enola::Platform.current("host_os" => "linux-gnu", "host_cpu" => "x86_64")
    assert_equal "darwin-arm64", Enola::Platform.current("host_os" => "darwin23", "host_cpu" => "arm64")
    assert_equal "windows-amd64", Enola::Platform.current("host_os" => "mingw32", "host_cpu" => "x86_64")
    assert_equal "linux-arm64", Enola::Platform.current("host_os" => "linux", "host_cpu" => "aarch64")
  end

  def test_refuses_a_platform_upstream_does_not_release
    error = assert_raises(Enola::UnsupportedPlatform) { Enola::Platform.current("host_os" => "freebsd", "host_cpu" => "x86_64") }

    assert_match(/no enola release for freebsd on x86_64/, error.message)
  end
end
