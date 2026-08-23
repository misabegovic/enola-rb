# frozen_string_literal: true

require "digest"
require "fileutils"
require "net/http"
require "open3"
require "tmpdir"
require "uri"

module Enola
  class Fetcher
    REDIRECTS = 5

    def initialize(channel: Enola.channel, cache_root: Enola.cache_root, platform: Platform.current)
      @channel = channel
      @cache_root = cache_root
      @platform = platform
    end

    def binary_path
      File.join(@channel.cache_dir(@cache_root), Platform.windows?(@platform) ? "enola.exe" : "enola")
    end

    def cached?
      File.executable?(binary_path)
    end

    def fetch
      return binary_path if cached?

      Dir.mktmpdir("enola-fetch") do |work|
        asset = @channel.asset(@platform)
        tarball = File.join(work, asset)
        write(@channel.url(asset), tarball)
        verify(tarball, read(@channel.url(@channel.checksum_asset(@platform))), asset)
        unpack(tarball, work)
      end
      binary_path
    end

    private

    def verify(tarball, checksum_text, asset)
      expected = checksum_text.split.first.to_s.downcase
      actual = Digest::SHA256.file(tarball).hexdigest
      return if !expected.empty? && expected == actual

      raise Unverified, "#{asset} did not match the checksum #{@channel.name} published for #{@channel.version} " \
                        "(expected #{expected.empty? ? 'nothing readable' : expected[0, 12]}, got #{actual[0, 12]}); nothing was installed"
    end

    def unpack(tarball, work)
      unpacked = File.join(work, "unpacked")
      FileUtils.mkdir_p(unpacked)
      _, err, status = Open3.capture3("tar", "xzf", tarball, "-C", unpacked)
      raise Unavailable, "could not unpack #{File.basename(tarball)}: #{err.strip}" unless status.success?

      inner = Dir.children(unpacked).find { |name| name.start_with?("#{@channel.asset_prefix}-") && !name.end_with?(".tar.gz") }
      raise Unavailable, "#{File.basename(tarball)} holds no #{@channel.asset_prefix} binary" unless inner

      dir = @channel.cache_dir(@cache_root)
      begin
        FileUtils.mkdir_p(dir)
      rescue SystemCallError => e
        raise Unavailable, "cannot write the cache at #{dir} (#{e.message}); set ENOLA_CACHE_DIR to a writable directory"
      end
      FileUtils.mv(File.join(unpacked, inner), binary_path, force: true)
      FileUtils.chmod(0o755, binary_path)
      %w[LICENSE NOTICE].each do |extra|
        source = File.join(unpacked, extra)
        FileUtils.mv(source, File.join(dir, extra), force: true) if File.exist?(source)
      end
    end

    def read(url)
      body = +""
      stream(url) { |chunk| body << chunk }
      body
    end

    def write(url, path)
      File.open(path, "wb") { |file| stream(url) { |chunk| file.write(chunk) } }
    end

    def stream(url, hops = 0, &block)
      uri = URI(url)
      return File.open(uri.path, "rb") { |file| file.each(nil, 1 << 16, &block) } if uri.scheme == "file"

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 15, read_timeout: 60) do |http|
        http.request(Net::HTTP::Get.new(uri)) do |response|
          case response
          when Net::HTTPRedirection
            raise Unavailable, "too many redirects fetching #{url}" if hops >= REDIRECTS

            return stream(response["location"], hops + 1, &block)
          when Net::HTTPSuccess
            response.read_body(&block)
          else
            raise Unavailable, "#{url} answered #{response.code}"
          end
        end
      end
    rescue SocketError, SystemCallError, Net::OpenTimeout, Net::ReadTimeout, IOError => e
      raise Unavailable, offline_message(e)
    end

    def offline_message(error)
      "enola #{@channel} is not in the cache at #{@channel.cache_dir(@cache_root)} and could not be fetched " \
        "from #{@channel.release_base} (#{error.class}: #{error.message}); connect once, or place the verified binary there"
    end
  end
end
