# frozen_string_literal: true

require "json"

module Enola
  module CLI
    def self.start(argv, stderr: $stderr, stdout: $stdout)
      case argv.first
      when "--wrapper-probe"
        found = Resolver.new.resolve
        stdout.puts JSON.pretty_generate(Probe.new(found.path).report.merge(source: found.source))
        0
      when "--wrapper-fetch"
        stdout.puts Fetcher.new.fetch
        0
      when "init"
        root = argv[1] || "."
        written = Config.write_default(root)
        stdout.puts(written ? "wrote #{written}" : "#{Config.path(root)} already exists, left as is")
        Runner.new(stderr: stderr).run(["constraints", "init", root])
      else
        Runner.new.exec(argv)
      end
    rescue Error => e
      stderr.puts "enola: #{e.message}"
      127
    end
  end
end
