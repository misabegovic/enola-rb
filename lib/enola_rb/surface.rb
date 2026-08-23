# frozen_string_literal: true

module EnolaRb
  module Surface
    REMEDY = {
      upstream: "upgrade the enola gem to a release that carries it, or switch the Gemfile to munola",
      munola: "upgrade the munola gem"
    }.freeze

    def self.require!(name, binary:, channel: Enola.channel)
      return binary if Enola::Probe.new(binary).capabilities.fetch(name.to_sym, false)

      remedy = REMEDY.fetch(channel.name.to_sym, "upgrade the gem that pins this binary")
      raise Enola::Unavailable, "the #{channel} binary at #{binary} has no `#{name}` surface; #{remedy}"
    end
  end
end
