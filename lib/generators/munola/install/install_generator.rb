# frozen_string_literal: true

require "rails/generators"
require "munola"

module Munola
  module Generators
    class InstallGenerator < Rails::Generators::Base
      desc "Writes enola/constraints/ and the munola recipe catalogue, binding what the tree shows a need for"
      class_option :tenant_column, type: :string, default: nil, desc: "The column most tables carry; confirmed against db/schema.rb"

      def install
        Munola::Installer.new(destination_root, tenant_column: options[:tenant_column]).install.lines.each { |line| say line }
      rescue Enola::Error => e
        raise Thor::Error, "munola: #{e.message}"
      end
    end
  end
end
