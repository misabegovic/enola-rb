# frozen_string_literal: true

require "rails/generators"
require "enola-rb"

module Enola
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Writes enola/constraints/ from the guides' starter laws and binds the shipped recipes whose roles resolve"
      def install
        EnolaRb::Installer.new(destination_root).install.lines.each { |line| say line }
      rescue Enola::Error => e
        raise Thor::Error, "enola: #{e.message}"
      end
    end
  end
end
