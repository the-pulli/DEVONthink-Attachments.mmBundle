#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../Support/bin/update"

class UpdaterTest < Minitest::Test
  def test_newer_detects_higher_version
    assert Updater.newer?("1.2.0", "1.1.0")
    assert Updater.newer?("1.1.1", "1.1.0")
    assert Updater.newer?("2.0.0", "1.9.9")
  end

  def test_newer_is_numeric_not_lexical
    assert Updater.newer?("1.10.0", "1.2.0")
    assert Updater.newer?("1.2.0", "1.10.0") == false
  end

  def test_newer_false_for_equal_or_lower
    refute Updater.newer?("1.1.0", "1.1.0")
    refute Updater.newer?("1.0.0", "1.1.0")
  end

  def test_newer_nil_latest_is_never_an_update
    # Couldn't read the remote version → never claim an update exists.
    refute Updater.newer?(nil, "1.1.0")
  end

  def test_newer_nil_current_offers_update
    # Pre-versioning bundle with no <version> key in info.plist → treat as stale
    # so the update is offered (installing it writes a plist that has the key).
    assert Updater.newer?("1.1.0", nil)
    refute Updater.newer?(nil, nil)
  end

  def test_current_version_reads_info_plist
    assert_match(/\A\d+\.\d+\.\d+\z/, Updater.current_version)
  end
end
