# frozen_string_literal: true

module MunolaRb
  # The enola:* tasks come from the enola-rb railtie and drive whatever channel
  # is installed; requiring munola installs its resolver, so under this gem
  # they run the munola binary. Only the generator is munola's own.
  class Railtie < Rails::Railtie
    generators { require_relative "../generators/munola/install/install_generator" }
  end
end
