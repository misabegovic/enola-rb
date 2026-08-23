# frozen_string_literal: true

require_relative "test_helper"

class ResolverTest < EnolaTest
  def test_cache_wins_over_everything
    fetcher.fetch
    other = FakeRelease.binary(File.join(@tmp, "bin"), Enola::VERSION)

    found = resolver(path: File.dirname(other)).resolve

    assert_equal "cache", found.source
    assert_equal fetcher.binary_path, found.path
  end

  def test_a_path_binary_is_used_only_when_its_version_matches_the_pin
    matching = FakeRelease.binary(File.join(@tmp, "bin"), Enola::VERSION)

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

    assert_match(/the enola on PATH is 0\.3\.9, the Gemfile pins #{Enola::VERSION}/, error.message)
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
