# frozen_string_literal: true

require_relative "test_helper"
require "yaml"

class ConfigTest < EnolaTest
  def test_writes_both_providers_with_this_ruby_and_the_vendored_script
    root = File.join(@tmp, "app")
    FileUtils.mkdir_p(root)

    written = Enola::Config.write_default(root, ruby: "/opt/ruby/bin/ruby")
    config = YAML.safe_load(File.read(written))

    assert_equal File.join(root, "mcp-arch.yaml"), written
    assert_equal ".", config["repo"]
    assert_equal ["."], config["repos"]
    assert_includes config["ignore"], "**/vendor/**"
    assert_equal %w[prism rubydex], config["providers"].map { |p| p["name"] }
    assert_equal ["/opt/ruby/bin/ruby", Enola::Providers.prism_script], config["providers"][0]["command"]
    assert_equal Enola::Providers.prism_version, config["providers"][0]["expected_version"]
    refute config["providers"][1].key?("command")
    assert_equal "0.4.0", config["providers"][1]["expected_version"]
  end

  def test_never_overwrites_a_config_that_exists
    root = File.join(@tmp, "app")
    FileUtils.mkdir_p(root)
    File.write(File.join(root, "mcp-arch.yaml"), "repos: [.]\n")

    assert_nil Enola::Config.write_default(root)
    assert_equal "repos: [.]\n", File.read(File.join(root, "mcp-arch.yaml"))
  end
end
