# frozen_string_literal: true

require "enola"
require "enola-rb"
require_relative "munola/version"
require_relative "munola/channel"
require_relative "munola/catalogue"
require_relative "munola/detector"
require_relative "munola/providers_config"
require_relative "munola/installer"
require_relative "munola/cli"
require_relative "munola/railtie" if defined?(Rails::Railtie)

Enola.channel = Munola::CHANNEL
Enola.resolver_factory = -> { Munola::Resolver.new(channel: Munola::CHANNEL) }

module Munola
end
