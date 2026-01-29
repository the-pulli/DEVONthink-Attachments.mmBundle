#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "devonthink"

config = DEVONthink.load_config
attachments = DEVONthink.parse_attachments(ENV.fetch("MM_FILES"), ENV.fetch("MM_MESSAGE_ID"))
attachments = DEVONthink.apply_rules(attachments, config[:rules])

exit 0 if attachments.empty?

attachments = DEVONthink.transform_for_applescript(attachments)
substitutions = DEVONthink.build_substitutions(attachments, config)
apple_script = DEVONthink.build_applescript(substitutions)

exec "osascript", "-e", apple_script
