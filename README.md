# About DEVONthink-Attachments Bundle

This bundle enhances MailMate to add attachments to DEVONthink (via AppleScript).

## Installation

Place the bundle in `~/Library/Application Support/MailMate/Bundles`. Requires Ruby 2.4+ (macOS includes Ruby 2.6).

## Usage

Three commands are available:

- **Add...** (Ctrl+A) - Adds attachments to DEVONthink
- **Attachment Rules...** (Ctrl+R) - Opens your custom rules file
- **Check for Updates...** (Ctrl+U) - Checks GitHub for a newer release and updates the bundle in place

To automate, add a MailMate rule for your inbox to execute the `Add...` command.

## Updating

Run **Check for Updates...** (Ctrl+U). It compares the installed version (from
`info.plist`) with the latest [GitHub release](https://github.com/the-pulli/DEVONthink-Attachments.mmBundle/releases).
If a newer release exists, it shows the release notes in a dialog and — after you
click **Update** — downloads and installs it over the bundle. It then offers to
**Restart** MailMate for you (a detached helper quits MailMate and relaunches it
once it has fully closed); choose **Later** to restart manually instead. Your
rules file lives outside the bundle and is never touched.

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
