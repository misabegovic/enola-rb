# frozen_string_literal: true

require "munola"
require "enola-rb"
require_relative "munola_rb/version"
begin
  require "rails"
rescue LoadError
  nil
end
require_relative "munola_rb/railtie" if defined?(Rails::Railtie)

module MunolaRb
end
