# frozen_string_literal: true

module Munola
  class Railtie < Rails::Railtie
    generators { require_relative "../generators/munola/install/install_generator" }
  end
end
