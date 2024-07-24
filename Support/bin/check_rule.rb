#!/usr/bin/env ruby
# frozen_string_literal: true

require "fileutils"

blueprint = "#{__dir__}/rule.rb"
custom = "#{__dir__}/custom_rule.rb"
FileUtils.cp(blueprint, custom) if !File.exist?(custom) && File.exist?(blueprint)

exec "open '#{custom}'"
