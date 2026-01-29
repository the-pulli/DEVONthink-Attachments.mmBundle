# frozen_string_literal: true

require "cgi"
require "json"
require "date"

module DEVONthink
  DEFAULTS = {
    rules: {
      filename_reject!: /signature|msg|encrypted|openpgp|smime\.p7s|asc/i,
      mime_reject!: /pgp-encrypted/i,
      mime_select!: /application/i
    },
    delete_duplicate_record: true,
    move_to_trash: true
  }.freeze

  CONFIG_DIR = File.expand_path("~/Library/Application Support/MailMate/DEVONthink Attachments Config")
  CONFIG_PATH = "#{CONFIG_DIR}/rules.rb"

  class << self
    def load_config
      config = { rules: DEFAULTS[:rules].dup }
      config[:delete_duplicate_record] = DEFAULTS[:delete_duplicate_record]
      config[:move_to_trash] = DEFAULTS[:move_to_trash]

      if File.exist?(CONFIG_PATH)
        user = eval(File.read(CONFIG_PATH)) # rubocop:disable Security/Eval
        config[:rules].merge!(user[:rules]) if user[:rules]
        config[:delete_duplicate_record] = user[:delete_duplicate_record] if user.key?(:delete_duplicate_record)
        config[:move_to_trash] = user[:move_to_trash] if user.key?(:move_to_trash)
      end

      config
    end

    def parse_attachments(mm_files_json, message_id)
      message_url = "message://%3c#{CGI.escape(message_id)}%3e"
      JSON.parse(mm_files_json, symbolize_names: true).map do |f|
        {
          filepath: f[:filePath],
          filename: File.basename(f[:filePath]),
          mime: f[:MIME],
          url: message_url
        }
      end
    end

    def apply_rules(attachments, rules)
      rules.each do |key, pattern|
        method_name, attribute = key.to_s.split("_").reverse.map(&:to_sym)
        attachments.send(method_name) { |a| a[attribute].match?(pattern) }
      end
      attachments
    end

    def transform_for_applescript(attachments)
      attachments.map do |a|
        {
          devonthinkFilepath: a[:filepath],
          devonthinkFilename: a[:filename],
          mime: a[:mime],
          url: a[:url]
        }
      end
    end

    def build_substitutions(attachments, config)
      {
        "DEVONTHINK_DATE" => Date.today.strftime("%Y-%m-%d"),
        "DEVONTHINK_DELETE_DUPLICATE_RECORD" => config[:delete_duplicate_record].to_s,
        "DEVONTHINK_JSON" => JSON.generate(attachments).inspect,
        "DEVONTHINK_MOVE_TO_TRASH" => config[:move_to_trash].to_s,
        "DEVONTHINK_URL" => attachments.first[:url]
      }
    end

    def build_applescript(substitutions)
      template = File.read("#{__dir__}/devonthink.applescript")
      template.gsub(/DEVONTHINK_\w+/, substitutions)
    end
  end
end
