# frozen_string_literal: true

module Enola
  class Runner
    def initialize(resolver: Resolver.new, channel: Enola.channel, stderr: $stderr)
      @resolver = resolver
      @channel = channel
      @stderr = stderr
    end

    def command(argv)
      found = @resolver.resolve
      @stderr.puts "enola: #{@channel} via #{found.source} (#{found.path})" if argv.include?("--verbose")
      [found.path, *argv]
    end

    def run(argv)
      system(*command(argv))
      $?.exitstatus || 1
    end

    def exec(argv)
      Kernel.exec(*command(argv))
    end
  end
end
