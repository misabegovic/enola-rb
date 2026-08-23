# frozen_string_literal: true

require "minitest/autorun"
require "digest"
require "fileutils"
require "tmpdir"
require "enola"

module FakeRelease
  SCRIPT = <<~SH
    #!/bin/sh
    case "$1" in
      --version) echo "enola version VERSION"; exit 0 ;;
      providers)
        case "$2" in
          fetch) echo "rubydex VERSION fetched"; exit 0 ;;
          list) echo "  rubydex  0.4.0 at /nowhere/librubydex_sys.so"; exit 0 ;;
        esac
        echo "Usage: enola providers"; exit 2 ;;
      constraints|check|plan) echo "Usage: enola $1"; exit 2 ;;
      hook) echo 'unknown command "hook" (expected one of: check)'; exit 1 ;;
      fail) exit 3 ;;
      echo) shift; echo "$@"; exit 0 ;;
    esac
    exit 0
  SH

  def self.build(root, platform:, version: Enola::VERSION, prefix: "enola", checksum: nil)
    release = File.join(root, "v#{version}")
    FileUtils.mkdir_p(release)
    Dir.mktmpdir do |stage|
      name = "#{prefix}-#{version}-#{platform}"
      File.write(File.join(stage, name), SCRIPT.sub("VERSION", version))
      FileUtils.chmod(0o755, File.join(stage, name))
      File.write(File.join(stage, "LICENSE"), "license")
      system("tar", "czf", File.join(release, "#{name}.tar.gz"), "-C", stage, name, "LICENSE", exception: true)
    end
    tarball = File.join(release, "#{prefix}-#{version}-#{platform}.tar.gz")
    digest = checksum || Digest::SHA256.file(tarball).hexdigest
    File.write(File.join(release, "#{prefix}-#{version}-#{platform}.sha256"), "#{digest}  #{File.basename(tarball)}\n")
    "file://#{root}"
  end

  def self.binary(dir, version)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, "enola")
    File.write(path, SCRIPT.sub("VERSION", version))
    FileUtils.chmod(0o755, path)
    path
  end
end

class EnolaTest < Minitest::Test
  PLATFORM = "linux-amd64"

  def setup
    @tmp = Dir.mktmpdir("enola-test")
    @cache = File.join(@tmp, "cache")
    @release_base = FakeRelease.build(File.join(@tmp, "releases"), platform: PLATFORM)
    @channel = Enola::Channel.new(name: "upstream", release_base: @release_base, version: Enola::VERSION, asset_prefix: "enola")
  end

  def teardown
    FileUtils.rm_rf(@tmp)
  end

  def fetcher(channel = @channel)
    Enola::Fetcher.new(channel: channel, cache_root: @cache, platform: PLATFORM)
  end

  def resolver(channel: @channel, path: "")
    Enola::Resolver.new(channel: channel, cache_root: @cache, platform: PLATFORM, path: path)
  end

  def unreachable
    Enola::Channel.new(name: "upstream", release_base: "file://#{@tmp}/missing", version: Enola::VERSION, asset_prefix: "enola")
  end
end
