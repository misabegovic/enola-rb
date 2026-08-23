# frozen_string_literal: true

require_relative "enola/version"
require_relative "enola/error"
require_relative "enola/channel"
require_relative "enola/platform"
require_relative "enola/fetcher"
require_relative "enola/probe"
require_relative "enola/providers"
require_relative "enola/config"
require_relative "enola/resolver"
require_relative "enola/runner"
require_relative "enola/cli"

module Enola
  class << self
    attr_writer :channel

    def channel
      @channel ||= Channel::UPSTREAM
    end

    def cache_root
      ENV.fetch("ENOLA_CACHE_DIR") { File.join(Dir.home, ".cache", "enola") }
    end
  end
end
