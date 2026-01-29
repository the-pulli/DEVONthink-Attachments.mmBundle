# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **MailMate bundle** that automates archiving email attachments to DEVONthink. It integrates with MailMate via AppleScript and Ruby scripts to filter, process, and import attachments.

## Architecture

```
Commands/           → MailMate command definitions (Ctrl+A to add, Ctrl+R for rules)
Support/bin/        → Core logic
  add.rb            → Entry point: orchestrates the flow
  devonthink.rb     → DEVONthink module with all business logic
  config_template.rb → Template for new user config files
  open_rules.rb     → Creates config dir if needed, opens user's rules.rb
  devonthink.applescript → AppleScript that communicates with DEVONthink
test/               → Tests
  devonthink_test.rb → Minitest tests for DEVONthink module
```

### User Config Location (outside bundle)

```
~/Library/Application Support/MailMate/DEVONthink Attachments Config/
  rules.rb          → User's custom rules (persists across bundle updates)
```

### Data Flow

```
MailMate (Ctrl+A) → add.rb → load config → parse attachments → apply rules → transform → AppleScript → DEVONthink
```

### Config Merge Behavior

- Defaults are defined in `devonthink.rb`
- User config is a Ruby hash in `~/Library/.../DEVONthink Attachments Config/rules.rb`
- Rules are merged: user's rule keys override defaults, other defaults are kept
- Boolean options (`delete_duplicate_record`, `move_to_trash`) override if present

## Running Tests

```bash
ruby test/devonthink_test.rb
```

CI runs automatically on push/PR to main via GitHub Actions (`.github/workflows/test.yml`).

## Ruby Requirements

- Minimum version: **Ruby 2.4** (uses `match?`)
- macOS bundles Ruby 2.6.x (sufficient)
- Commands use `/usr/bin/env ruby` for version manager compatibility

## No Build System

- Bundle is distributed as-is (macOS package structure)
- Ruby uses standard library only (no Gemfile)
- Installation: Copy to `~/Library/Application Support/MailMate/Bundles/`
- **Update safe**: User config lives outside bundle, so bundle can be replaced entirely

## Manual Testing in MailMate

1. Select an email with attachments
2. Press Ctrl+A to trigger the Add command
3. Check DEVONthink for imported files and notification

## Important Notes

- **MailMate commands require bash shebang**: Commands must start with `#!/usr/bin/env bash` - MailMate won't execute single-line commands without it
- AppleScript escaping: Uses `.inspect` on JSON to escape quotes
- OCR: Triggers only on blank PDFs (0 word count) and non-encrypted records
- Duplicates: Controlled by `delete_duplicate_record` and `move_to_trash` in user config
