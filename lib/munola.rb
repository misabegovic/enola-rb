# frozen_string_literal: true

require "enola"
require_relative "munola/version"
require_relative "munola/channel"
require_relative "munola/catalogue"
require_relative "munola/detector"
require_relative "munola/providers_config"
require_relative "munola/installer"
require_relative "munola/cli"
# munola is a wrapper first. enola-rb requires rails because it is the Rails
# layer; munola only registers its generator when the application has already
# loaded Rails, so driving the binary alone costs nothing.
require_relative "munola/railtie" if defined?(Rails::Railtie)

Enola.channel = Munola::CHANNEL
Enola.resolver_factory = -> { Munola::Resolver.new(channel: Munola::CHANNEL) }

module Munola
end
