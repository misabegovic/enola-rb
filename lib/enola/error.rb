# frozen_string_literal: true

module Enola
  class Error < StandardError; end

  class Unavailable < Error; end

  class Unverified < Error; end

  class UnsupportedPlatform < Error; end
end
