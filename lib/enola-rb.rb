# frozen_string_literal: true

require "enola"
require_relative "enola_rb/version"
require_relative "enola_rb/guides"
require_relative "enola_rb/surface"
require_relative "enola_rb/installer"
begin
  require "rails"
rescue LoadError
  nil
end
require_relative "enola_rb/railtie" if defined?(Rails::Railtie)

module EnolaRb
  TASKS = File.expand_path("enola_rb/tasks.rake", __dir__)
end
