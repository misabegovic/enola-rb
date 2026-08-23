# frozen_string_literal: true

require "enola"
require_relative "munola/version"
require_relative "munola/channel"
require_relative "munola/catalogue"
require_relative "munola/detector"
require_relative "munola/providers_config"
require_relative "munola/installer"
require_relative "munola/cli"

Enola.channel = Munola::CHANNEL
Enola.resolver_factory = -> { Munola::Resolver.new(channel: Munola::CHANNEL) }

module Munola
end
