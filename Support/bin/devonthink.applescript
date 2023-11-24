use AppleScript version "2.8"
use framework "Foundation"
use scripting additions

property ca : a reference to current application
property NSData : a reference to ca's NSData
property NSDictionary : a reference to ca's NSDictionary
property NSJSONSerialization : a reference to ca's NSJSONSerialization
property NSString : a reference to ca's NSString
property NSUTF8StringEncoding : a reference to 4

on parseJSON(theJson)
  set theJSONString to (NSString's stringWithString:theJson)
  set JSONdata to (theJSONString's dataUsingEncoding:NSUTF8StringEncoding)
  set [elements, E] to (NSJSONSerialization's JSONObjectWithData:JSONdata options:0 |error|:(reference))
  if E ≠ missing value then error E
  tell elements to if its isKindOfClass:NSDictionary then return it as record
  elements as list
end parseJSON

on cleanDuplicateRecord(theRecord)
  tell application id "DNtp"
    set theDuplicates to duplicates of theRecord
    set deleteDuplicateRecord to DEVONTHINK_DELETE_DUPLICATE_RECORD
    set moveToTrash to DEVONTHINK_MOVE_TO_TRASH
    set isDeleted to false
    if deleteDuplicateRecord then
      if (length of theDuplicates is greater than 0) then
        if moveToTrash then
          move record theRecord to (trash group of database of theRecord)
        else
          delete record theRecord
        end if
        set isDeleted to true
      end if
    end if
  end tell
  return isDeleted
end cleanDuplicateRecord

try
    tell application id "DNtp"
        set theAttachments to my parseJSON(DEVONTHINK_JSON)
        repeat with theAttachment in theAttachments
            set theRecord to import (devonthinkFilepath of theAttachment)

            if theRecord is not missing value then
              if (creation date of theRecord) is not missing value then
                set theModificationDate to creation date of theRecord
              else
                set theModificationDate to "DEVONTHINK_DATE"
              end if

              set modification date of theRecord to theModificationDate

              set the URL of theRecord to "DEVONTHINK_URL" # Allows it to be opened in MailMate using ⌃⌘U

              if ((type of theRecord) is PDF document) and ((word count of theRecord) is 0) and ((encrypted of theRecord) is false) then
                set ocrRecord to (ocr file path of theRecord waiting for reply true)
                set modification date of ocrRecord to theModificationDate
                set the URL of ocrRecord to "DEVONTHINK_URL" # Allows it to be opened in MailMate using ⌃⌘U
                set theResult to delete record theRecord
                my cleanDuplicateRecord(ocrRecord)
              end if

              set wasDeleted to my cleanDuplicateRecord(theRecord)
              if wasDeleted is false then
                display notification (devonthinkFilename of theAttachment) & " imported." with title "MailMate"
              end if
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
