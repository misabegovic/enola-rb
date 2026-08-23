# frozen_string_literal: true

module Munola
  CHANNEL = Enola::Channel.new(
    name: "munola",
    release_base: "https://github.com/misabegovic/enola/releases/download",
    version: VERSION,
    asset_prefix: "enola",
    tag_prefix: "munola-v"
  ).freeze

  # The binary this channel drives is fetched from the fork's releases; until
  # the first one is cut, MUNOLA_BINARY names a binary to drive instead, and
  # every command says which one answered.
  class Resolver < Enola::Resolver
    def initialize(override: ENV.fetch("MUNOLA_BINARY", nil), **options)
      super(**options)
      @override = override
    end

    def resolve
      return super unless @override

      raise Enola::Unavailable, "MUNOLA_BINARY names #{@override}, which is not executable" unless File.executable?(@override)

      Found.new(@override, "MUNOLA_BINARY (#{Enola::Probe.new(@override).version || 'no version answered'})")
    end
  end

  def self.resolve
    Resolver.new(channel: CHANNEL).resolve
  end

  def self.channel_line(found = resolve)
    "munola #{VERSION}, built on enola #{UPSTREAM_VERSION}; binary via #{found.source} (#{found.path})"
  end
end
