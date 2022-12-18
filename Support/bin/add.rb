#!/usr/bin/env ruby

require 'cgi'
require 'json'
require_relative 'files'
require_relative 'rule'

url = "message://%3c#{CGI.escape(ENV.fetch('MM_MESSAGE_ID'))}%3e"

attachments = JSON.parse(ENV.fetch('MM_FILES'), { symbolize_names: true }).map do |f|
  { filepath: f[:filePath], filename: File.basename(f[:filePath]), mime: f[:MIME], url: url }
end

DEVONthink::Files.new(DEVONthink::Rule.new(attachments).apply).add
