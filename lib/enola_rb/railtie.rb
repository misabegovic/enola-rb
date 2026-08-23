# frozen_string_literal: true

module EnolaRb
  class Railtie < Rails::Railtie
    rake_tasks { load EnolaRb::TASKS }
    generators { require_relative "../generators/enola/install/install_generator" }
  end
end
