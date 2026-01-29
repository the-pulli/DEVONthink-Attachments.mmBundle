#!/usr/bin/env ruby
# frozen_string_literal: true

CONFIG_DIR = File.expand_path("~/Library/Application Support/MailMate/DEVONthink Attachments Config")
CONFIG_PATH = "#{CONFIG_DIR}/rules.rb"
TEMPLATE_PATH = "#{__dir__}/config_template.rb"

unless File.exist?(CONFIG_PATH)
  Dir.mkdir(CONFIG_DIR) unless Dir.exist?(CONFIG_DIR)
  IO.copy_stream(TEMPLATE_PATH, CONFIG_PATH)
end

exec "open", CONFIG_PATH
