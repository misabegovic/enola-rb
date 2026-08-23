# frozen_string_literal: true

require_relative "test_helper"

class ProbeTest < EnolaTest
  def test_reads_the_version_and_probes_each_surface
    probe = Enola::Probe.new(fetcher.fetch)

    assert_equal Enola::UPSTREAM_VERSION, probe.version
    assert_equal({ constraints: true, providers: true, check: true, plan: true, hook: false }, probe.capabilities)
  end

  def test_report_names_channel_pin_binary_and_answers
    report = Enola::Probe.new(fetcher.fetch).report(channel: @channel)

    assert_equal %i[channel pinned binary version capabilities], report.keys
    assert_equal "upstream", report[:channel]
  end

  def test_an_unrunnable_binary_answers_nil_and_false
    probe = Enola::Probe.new(File.join(@tmp, "nowhere"))

    assert_nil probe.version
    assert_equal false, probe.capabilities[:constraints]
  end
end
