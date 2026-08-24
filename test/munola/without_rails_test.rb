# frozen_string_literal: true

require_relative "../test_helper"

# munola is a wrapper first: a project that only drives the binary should not
# load Rails by requiring it, even where railties is installed.
class MunolaWithoutRailsTest < EnolaTest
  def test_requiring_munola_alone_loads_no_rails
    script = 'require "munola"; puts [defined?(Rails).inspect, Munola::CHANNEL.name, Enola.resolver.class].join(" ")'
    out = IO.popen([RbConfig.ruby, "-I#{File.expand_path('../../lib', __dir__)}", "-e", script], &:read)

    assert_equal 'nil munola Munola::Resolver', out.strip
  end

  def test_the_generator_registers_when_the_application_has_loaded_rails
    script = 'require "rails"; require "munola"; puts [defined?(Munola::Railtie).inspect, Enola.channel.name].join(" ")'
    out = IO.popen([RbConfig.ruby, "-I#{File.expand_path('../../lib', __dir__)}", "-e", script], &:read)

    assert_equal '"constant" munola', out.strip
  end
end
