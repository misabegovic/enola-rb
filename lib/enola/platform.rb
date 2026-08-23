# frozen_string_literal: true

require "rbconfig"

module Enola
  module Platform
    OS = { "linux" => "linux", "darwin" => "darwin", "mingw" => "windows", "mswin" => "windows" }.freeze
    ARCH = { "x86_64" => "amd64", "amd64" => "amd64", "aarch64" => "arm64", "arm64" => "arm64" }.freeze

    def self.current(config = RbConfig::CONFIG)
      os = OS.find { |key, _| config["host_os"].include?(key) }&.last
      arch = ARCH[config["host_cpu"]]
      raise UnsupportedPlatform, "no enola release for #{config['host_os']} on #{config['host_cpu']}" unless os && arch

      "#{os}-#{arch}"
    end

    def self.windows?(platform)
      platform.start_with?("windows")
    end
  end
end
