# frozen_string_literal: true

require "date"
require "json"
require_relative "rule"

module DEVONthink
  # Handles adding files to DT
  class Files
    def initialize(attachments)
      @attachments = attachments.map do |hsh|
        hsh.transform_keys { |k| k.to_s.include?("file") ? k.to_s.sub("file", "devonthinkFile").to_sym : k }
      end
      # inspect is necessary due to escaping double quotes for AppleScript
      # TODO: possible bug, if filename contains double quotes
      @json = JSON.generate(@attachments).inspect
      @url = @attachments.first[:url]
      @date = Date.new.strftime("%Y-%m-%d")
    end

    def add
      map = {
        "DEVONTHINK_DATE" => @date,
        "DEVONTHINK_DELETE_DUPLICATE_RECORD" => Rule::DELETE_DUPLICATE_RECORD.to_s,
        "DEVONTHINK_JSON" => @json,
        "DEVONTHINK_MOVE_TO_TRASH" => Rule::MOVE_TO_TRASH.to_s,
        "DEVONTHINK_URL" => @url
      }
      re = Regexp.new(map.keys.map { |x| Regexp.escape(x) }.join("|"))
      # Use AppleScript to communicate with DEVONthink
      apple_script = File.read("#{__dir__}/devonthink.applescript").gsub(re, map)

      exec "osascript", "-e", apple_script
    end
  end
end
