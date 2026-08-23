# frozen_string_literal: true

require_relative "test_helper"
require "open3"

class RealFetchTest < Minitest::Test
  def test_fetches_the_upstream_release_and_runs_it
    skip "set ENOLA_REAL_FETCH=1 to fetch the upstream release over the network" unless ENV["ENOLA_REAL_FETCH"]

    Dir.mktmpdir("enola-real") do |cache|
      path = Enola::Fetcher.new(channel: Enola::Channel::UPSTREAM, cache_root: cache).fetch
      out, status = Open3.capture2e(path, "--version")

      assert status.success?
      assert_includes out, Enola::VERSION
      assert_equal Enola::VERSION, Enola::Probe.new(path).version
    end
  end
end
