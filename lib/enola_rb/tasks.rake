# frozen_string_literal: true

require "enola-rb"

namespace :enola do
  root = -> { defined?(Rails) && Rails.respond_to?(:root) && Rails.root ? Rails.root.to_s : Dir.pwd }
  run = lambda do |*args|
    status = Enola::Runner.new.run(args)
    abort("enola: exited #{status}") unless status.zero?
  rescue Enola::Error => e
    abort("enola: #{e.message}")
  end

  desc "Write enola/constraints/ from the guides' starter and bind the shipped recipes whose roles resolve"
  task :init do
    EnolaRb::Installer.new(root.call).install.lines.each { |line| puts line }
  rescue Enola::Error => e
    abort("enola: #{e.message}")
  end

  desc "Snapshot the application and pin the result as the baseline a change is graded against"
  task :snapshot do
    run.call("--generate", root.call)
    run.call("baseline", "pin", root.call)
  end

  desc "Grade the working tree against the pinned baseline; fails on a new breach of a declared law"
  task :check do
    run.call("check", "--fail-on", "constraints", root.call)
  end
end
