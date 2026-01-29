# About DEVONthink-Attachments Bundle

This bundle enhances MailMate to add attachments to DEVONthink (via AppleScript).

## Installation

Place the bundle in `~/Library/Application Support/MailMate/Bundles`. Requires Ruby 2.4+ (macOS includes Ruby 2.6).

## Usage

Two commands are available:

- **Add...** (Ctrl+A) - Adds attachments to DEVONthink
- **Attachment Rules...** (Ctrl+R) - Opens your custom rules file

To automate, add a MailMate rule for your inbox to execute the `Add...` command.

## Configuration

Your custom rules are stored **outside the bundle** at:
```
~/Library/Application Support/MailMate/DEVONthink Attachments Config/rules.rb
```

This means you can update the bundle without losing your settings. The config file is created automatically when you first run "Attachment Rules...".

Example config (only include what you want to override):
```ruby
{
  rules: {
    filename_reject!: /my-custom-pattern|unwanted/i,
  },
  delete_duplicate_record: true,
  move_to_trash: false,
}
```

## Upgrading

If upgrading from 0.2.0 or earlier, see [UPGRADE.md](UPGRADE.md) for migration instructions.

## Maintainer

[PuLLi](https://github.com/the-pulli)

## License

This MailMate bundle is open-sourced software licensed under the [MIT license](https://opensource.org/licenses/MIT).
