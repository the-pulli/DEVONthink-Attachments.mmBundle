require 'date'
require 'json'

module DEVONthink
  # Handles adding files to DT
  class Files
    def initialize(attachments)
      @attachments = attachments
    end

    def add
      # Convert Ruby Array with Hashes to an AppleScript Record String for the given files
      substitution = {
        '[' => '{',
        ']' => '}',
        '=>' => ':',
        ', ' => ',',
        ':' => ''
      }

      attachments_record = @attachments.to_s.gsub(/[\[\]=>:\\]*(, )*/, substitution)
                                       .gsub(/"(filepath|filename)"/, '\1')

      url = @attachments.first[:url]
      date = Date.new.strftime('%Y-%m-%d')

      # Use AppleScript to communicate with DEVONthink
      apple_script = <<~APS.strip
        use scripting additions

        try
            tell application id "DNtp"
                repeat with theAttachment in #{attachments_record}
                    set theRecord to import (filepath of theAttachment)

                    if theRecord is not missing value then
                      if (creation date of theRecord) is not missing value then
                        set theModificationDate to creation date of theRecord
                      else
                        set theModificationDate to "#{date}"
                      end if

                      set modification date of theRecord to theModificationDate

                      set the URL of theRecord to "#{url}" # Allows it to be opened in MailMate using ⌃⌘U

                      try
                        # Shell script hack from Jim N. (DEVONtechnologies)
                        do shell script "tail -n 5 " & (quoted form of (path of theRecord as string)) & " | grep Encrypt"
                        set theEncryption to true
                      on error
                        set theEncryption to false
                      end try

                      if (type of theRecord is PDF document) and (word count of theRecord is 0) and (theEncryption is false) then
                        set ocrRecord to (ocr file path of theRecord waiting for reply true)
                        set modification date of ocrRecord to theModificationDate
                        set the URL of ocrRecord to "#{url}" # Allows it to be opened in MailMate using ⌃⌘U
                        set theResult to delete record theRecord
                      end if

                      display notification (fileName of theAttachment) & " imported." with title "MailMate"
                    else
                      display notification "File could not be imported." with title "MailMate"
                    end if
                end repeat
            end tell
        on error errMsg number eNum
            tell application "System Events"
                activate
                display alert "DEVONthink: " & eNum message errMsg
            end tell
        end try
      APS

      system "osascript -e '#{apple_script}'"
    end
  end
end
