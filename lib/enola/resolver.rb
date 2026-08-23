# frozen_string_literal: true

module Enola
  class Resolver
    Found = Struct.new(:path, :source)

    def initialize(channel: Enola.channel, cache_root: Enola.cache_root, platform: Platform.current, path: ENV.fetch("PATH", ""))
      @channel = channel
      @fetcher = Fetcher.new(channel: channel, cache_root: cache_root, platform: platform)
      @path = path
    end

    def resolve
      return Found.new(@fetcher.binary_path, "cache") if @fetcher.cached?

      on_path, found_version = matching_path_binary
      return Found.new(on_path, "path") if on_path

      begin
        Found.new(@fetcher.fetch, "fetched")
      rescue Unavailable => e
        raise Unavailable, found_version ? "#{e.message}; the enola on PATH is #{found_version}, the Gemfile pins #{@channel.version}" : e.message
      end
    end

    EXECUTABLE = File.expand_path("../../exe/enola", __dir__)

    # A binstub is a script; the released binary is megabytes. The cap keeps the
    # whole-file read cheap and means a real binary is never slurped to be rejected.
    MAX_SCRIPT_BYTES = 64 * 1024

    private

    def matching_path_binary
      # A probe runs the candidate, and the candidate may be this wrapper wearing
      # another name. The marker travels into that child, and a resolver that finds
      # it declines to look at PATH — so the recursion is bounded by construction
      # rather than by how well the check below reads a file.
      return [nil, nil] if ENV[Probe::PROBE_ENV]

      candidate = @path.split(File::PATH_SEPARATOR).map { |dir| File.join(dir, "enola") }
                       .find { |bin| File.executable?(bin) && !wrapper?(bin) }
      return [nil, nil] unless candidate

      version = Probe.new(candidate).version
      version == @channel.version ? [candidate, version] : [nil, version]
    end

    # Bundler puts this gem's own exe on PATH, and a rubygems binstub for the
    # gem looks like a binary too; probing either would run the wrapper inside
    # itself without end.
    #
    # The whole file is read, not a fixed head. RubyGems writes a /bin/sh + `ruby -x`
    # polyglot preamble carrying the interpreter's absolute path, so the marker sits
    # ~580 bytes in — past the 512 this used to read, which made the guard miss every
    # real binstub and the wrapper probe itself without end.
    def wrapper?(bin)
      return true if File.realpath(bin) == File.realpath(EXECUTABLE)
      return false if File.size(bin) > MAX_SCRIPT_BYTES

      body = File.binread(bin)
      body.include?("Gem.activate_bin_path") || body.include?("Gem.bin_path") ||
        body.include?('require "enola"')
    rescue SystemCallError
      true
    end
  end
end
