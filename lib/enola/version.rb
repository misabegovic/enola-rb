# frozen_string_literal: true

module Enola
  # The release this wrapper drives. VERSION carries a patch segment for
  # wrapper-only fixes, so what to fetch is stated separately.
  UPSTREAM_VERSION = "0.4.4"
  VERSION = "#{UPSTREAM_VERSION}.1"
end
