# frozen_string_literal: true

require "open3"

module Enola
  class Probe
    SURFACES = %w[constraints providers check plan hook].freeze

    # A probed binary may be this wrapper wearing another name. The marker
    # travels into the child, where the resolver reads it and leaves PATH
    # alone, so a probe cannot start another one.
    PROBE_ENV = "ENOLA_RESOLVER_PROBE"
    CHILD_ENV = {PROBE_ENV => "1"}.freeze

    def initialize(binary)
      @binary = binary
    end

    def version
      out, status = Open3.capture2e(CHILD_ENV, @binary, "--version")
      return nil unless status.success?

      out[/\d+\.\d+\.\d+(?:[.-][\w.]+)?/]
    rescue SystemCallError
      nil
    end

    # A surface the binary has prints its usage (exit code 2 is its convention
    # for --help); one it lacks is refused by the top-level dispatch by name.
    def capabilities
      SURFACES.to_h do |surface|
        out, = Open3.capture2e(CHILD_ENV, @binary, surface, "--help")
        [surface.to_sym, !out.include?("unknown command \"#{surface}\"")]
      rescue SystemCallError
        [surface.to_sym, false]
      end
    end

    def report(channel: Enola.channel)
      { channel: channel.name, pinned: channel.version, binary: @binary, version: version, capabilities: capabilities }
    end
  end
end
