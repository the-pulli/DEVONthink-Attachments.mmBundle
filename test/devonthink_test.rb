#!/usr/bin/env ruby
# frozen_string_literal: true

require "minitest/autorun"
require_relative "../Support/bin/devonthink"

class DEVONthinkTest < Minitest::Test
  def test_defaults_exist
    assert_kind_of Hash, DEVONthink::DEFAULTS
    assert_kind_of Hash, DEVONthink::DEFAULTS[:rules]
    assert DEVONthink::DEFAULTS[:delete_duplicate_record]
    assert DEVONthink::DEFAULTS[:move_to_trash]
  end

  def test_parse_attachments
    mm_files = '[{"filePath":"/tmp/test.pdf","MIME":"application/pdf"}]'
    message_id = "abc123@example.com"

    result = DEVONthink.parse_attachments(mm_files, message_id)

    assert_equal 1, result.length
    assert_equal "/tmp/test.pdf", result[0][:filepath]
    assert_equal "test.pdf", result[0][:filename]
    assert_equal "application/pdf", result[0][:mime]
    assert_includes result[0][:url], "message://"
    assert_includes result[0][:url], "abc123"
  end

  def test_parse_attachments_multiple
    mm_files = '[{"filePath":"/tmp/a.pdf","MIME":"application/pdf"},{"filePath":"/tmp/b.doc","MIME":"application/msword"}]'

    result = DEVONthink.parse_attachments(mm_files, "test@example.com")

    assert_equal 2, result.length
    assert_equal "a.pdf", result[0][:filename]
    assert_equal "b.doc", result[1][:filename]
  end

  def test_apply_rules_reject_by_filename
    attachments = [
      { filename: "document.pdf", mime: "application/pdf" },
      { filename: "signature.png", mime: "image/png" },
      { filename: "encrypted.p7m", mime: "application/pkcs7-mime" }
    ]
    rules = { filename_reject!: /signature|encrypted/i }

    result = DEVONthink.apply_rules(attachments, rules)

    assert_equal 1, result.length
    assert_equal "document.pdf", result[0][:filename]
  end

  def test_apply_rules_select_by_mime
    attachments = [
      { filename: "doc.pdf", mime: "application/pdf" },
      { filename: "image.png", mime: "image/png" },
      { filename: "text.txt", mime: "text/plain" }
    ]
    rules = { mime_select!: /application/i }

    result = DEVONthink.apply_rules(attachments, rules)

    assert_equal 1, result.length
    assert_equal "application/pdf", result[0][:mime]
  end

  def test_apply_rules_combined
    attachments = [
      { filename: "invoice.pdf", mime: "application/pdf" },
      { filename: "signature.pdf", mime: "application/pdf" },
      { filename: "photo.jpg", mime: "image/jpeg" }
    ]
    rules = {
      filename_reject!: /signature/i,
      mime_select!: /application/i
    }

    result = DEVONthink.apply_rules(attachments, rules)

    assert_equal 1, result.length
    assert_equal "invoice.pdf", result[0][:filename]
  end

  def test_apply_rules_empty_result
    attachments = [
      { filename: "signature.png", mime: "image/png" }
    ]
    rules = { mime_select!: /application/i }

    result = DEVONthink.apply_rules(attachments, rules)

    assert_empty result
  end

  def test_transform_for_applescript
    attachments = [
      { filepath: "/tmp/test.pdf", filename: "test.pdf", mime: "application/pdf", url: "message://123" }
    ]

    result = DEVONthink.transform_for_applescript(attachments)

    assert_equal "/tmp/test.pdf", result[0][:devonthinkFilepath]
    assert_equal "test.pdf", result[0][:devonthinkFilename]
    assert_equal "application/pdf", result[0][:mime]
    assert_equal "message://123", result[0][:url]
  end

  def test_build_substitutions
    attachments = [{ url: "message://test123" }]
    config = { delete_duplicate_record: true, move_to_trash: false }

    result = DEVONthink.build_substitutions(attachments, config)

    assert_equal "true", result["DEVONTHINK_DELETE_DUPLICATE_RECORD"]
    assert_equal "false", result["DEVONTHINK_MOVE_TO_TRASH"]
    assert_equal "message://test123", result["DEVONTHINK_URL"]
    assert_match(/\d{4}-\d{2}-\d{2}/, result["DEVONTHINK_DATE"])
    assert_includes result["DEVONTHINK_JSON"], "message://test123"
  end

  def test_load_config_returns_defaults_when_no_user_config
    # Skip if user has a config file
    skip "User config exists" if File.exist?(DEVONthink::CONFIG_PATH)

    config = DEVONthink.load_config

    assert_equal DEVONthink::DEFAULTS[:delete_duplicate_record], config[:delete_duplicate_record]
    assert_equal DEVONthink::DEFAULTS[:move_to_trash], config[:move_to_trash]
    assert_equal DEVONthink::DEFAULTS[:rules].keys.sort, config[:rules].keys.sort
  end

  def test_default_rules_reject_common_signatures
    attachments = [
      { filename: "invoice.pdf", mime: "application/pdf" },
      { filename: "smime.p7s", mime: "application/pkcs7-signature" },
      { filename: "signature.asc", mime: "application/pgp-signature" },
      { filename: "encrypted.msg", mime: "application/vnd.ms-outlook" }
    ]

    result = DEVONthink.apply_rules(attachments.dup, DEVONthink::DEFAULTS[:rules])

    assert_equal 1, result.length
    assert_equal "invoice.pdf", result[0][:filename]
  end
end
