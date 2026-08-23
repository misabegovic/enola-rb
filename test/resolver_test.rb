# frozen_string_literal: true

require_relative "test_helper"

class ResolverTest < EnolaTest
  def test_cache_wins_over_everything
    fetcher.fetch
    other = FakeRelease.binary(File.join(@tmp, "bin"), Enola::UPSTREAM_VERSION)

    found = resolver(path: File.dirname(other)).resolve

    assert_equal "cache", found.source
    assert_equal fetcher.binary_path, found.path
  end

  def test_a_path_binary_is_used_only_when_its_version_matches_the_pin
    matching = FakeRelease.binary(File.join(@tmp, "bin"), Enola::UPSTREAM_VERSION)

    found = resolver(channel: unreachable, path: File.dirname(matching)).resolve

    assert_equal "path", found.source
    assert_equal matching, found.path
  end

  def test_a_path_binary_of_another_version_is_skipped_and_the_release_fetched
    other = FakeRelease.binary(File.join(@tmp, "bin"), "0.3.9")

    found = resolver(path: File.dirname(other)).resolve

    assert_equal "fetched", found.source
    assert_equal fetcher.binary_path, found.path
  end

  def test_the_refusal_names_the_path_version_and_the_pin_when_nothing_can_be_fetched
    other = FakeRelease.binary(File.join(@tmp, "bin"), "0.3.9")

    error = assert_raises(Enola::Unavailable) { resolver(channel: unreachable, path: File.dirname(other)).resolve }

    assert_match(/the enola on PATH is 0\.3\.9, the Gemfile pins #{Enola::UPSTREAM_VERSION}/, error.message)
  end

  # The binstub above is short enough that the guard's fixed-size read reaches
  # the marker. A real one is not: RubyGems writes a /bin/sh + `ruby -x` polyglot
  # preamble carrying the interpreter's absolute path, which pushes
  # `Gem.activate_bin_path` past the first 512 bytes. Reading a fixed head made the
  # wrapper probe itself, and probing itself has no bottom.
  def test_a_rubygems_binstub_is_recognised_however_long_its_preamble_is
    stub = FakeRelease.gem_binstub(File.join(@tmp, "bin"))

    refute_operator File.binread(stub).index("Gem.activate_bin_path"), :<, 512,
                    "fixture no longer reproduces the shape this guards against"
    assert resolver.send(:wrapper?, stub), "a RubyGems binstub must never be probed"
  end

  # Belt and braces: whatever a content check concludes, a probe must not be able
  # to start another one. The child is told it is inside a probe, and a resolver
  # that sees the marker declines to look at PATH at all.
  # Why the marker above is not belt and braces. A version manager's shim
  # carries none of the markers the content check looks for, so it reads as a
  # real binary and is probed; only the marker keeps that child from probing
  # in turn.
  def test_a_version_manager_shim_is_not_recognised_by_the_content_check
    shim = FakeRelease.shim(File.join(@tmp, "bin"))

    refute resolver.send(:wrapper?, shim)
  end

  def test_a_binary_probed_by_the_resolver_never_probes_in_turn
    matching = FakeRelease.binary(File.join(@tmp, "bin"), Enola::UPSTREAM_VERSION)

    ENV[Enola::Probe::PROBE_ENV] = "1"
    begin
      found = resolver(path: File.dirname(matching)).resolve
    ensure
      ENV.delete(Enola::Probe::PROBE_ENV)
    end

    assert_equal "fetched", found.source,
                 "a resolver running inside a probe must not probe PATH again"
  end

  def test_the_wrapper_itself_and_gem_binstubs_on_path_are_never_probed
    FileUtils.mkdir_p(File.join(@tmp, "bin"))
    stub = File.join(@tmp, "bin", "enola")
    File.write(stub, "#!/usr/bin/env ruby\nload Gem.activate_bin_path('enola', 'enola')\n")
    FileUtils.chmod(0o755, stub)
    exe_dir = File.dirname(Enola::Resolver::EXECUTABLE)

    found = resolver(path: [File.dirname(stub), exe_dir].join(File::PATH_SEPARATOR)).resolve

    assert_equal "fetched", found.source
  end
end
