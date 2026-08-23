# frozen_string_literal: true

module Enola
  Channel = Struct.new(:name, :release_base, :version, :asset_prefix, :tag_prefix, keyword_init: true) do
    def asset(platform)
      "#{asset_prefix}-#{version}-#{platform}.tar.gz"
    end

    def checksum_asset(platform)
      "#{asset_prefix}-#{version}-#{platform}.sha256"
    end

    def tag
      "#{tag_prefix || 'v'}#{version}"
    end

    def url(file)
      "#{release_base.chomp('/')}/#{tag}/#{file}"
    end

    def cache_dir(root)
      File.join(root, name, version)
    end

    def to_s
      "#{name} #{version}"
    end
  end

  Channel::UPSTREAM = Channel.new(
    name: "upstream",
    release_base: "https://github.com/enola-labs/enola/releases/download",
    version: VERSION,
    asset_prefix: "enola"
  ).freeze
end
