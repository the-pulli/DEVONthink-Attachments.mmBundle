# About DEVONthink-Attachments Bundle

This bundle enhances MailMate to add attachments to DEVONthink (via AppleScript).

## Installation

The bundle requires a recent version of Ruby installed. The bundle should be placed in `~/Library/Application Support/MailMate/Bundles`.
For the main command, it checks for Ruby environment managers like asdf, rbenv and rvm.

## Usage

It consists two commands, `Add...` and `Attachments Rules...`. The first one adds the attachments via AppleScript to DEVONthink.
The second one opens the Ruby class file, which consists the rules for adding filenames and mime types.
To automate adding attachments from MailMate to DEVONthink you can add a MailMate rule for your inbox to execute the Plugins `Add...` command.

## License

This MailMate bundle is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
