# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **MailMate bundle** that automates archiving email attachments to DEVONthink. It integrates with MailMate via AppleScript and Ruby scripts to filter, process, and import attachments.

## Architecture

```
Commands/           → MailMate command definitions (Ctrl+A add, Ctrl+R rules, Ctrl+U update)
Support/bin/        → Core logic
  add.rb            → Entry point: orchestrates the flow
  devonthink.rb     → DEVONthink module with all business logic
  config_template.rb → Template for new user config files
  open_rules.rb     → Creates config dir if needed, opens user's rules.rb
  update.rb         → Self-updater: checks GitHub release, confirms, replaces bundle
  devonthink.applescript → AppleScript that communicates with DEVONthink
test/               → Tests
  devonthink_test.rb → Minitest tests for DEVONthink module
  update_test.rb     → Minitest tests for the updater's version logic
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
- **Version lives in `info.plist`** (`<key>version</key>`). `update.rb` reads it to compare against the latest GitHub *release* (not tag). **When cutting a release, bump this key** so installed bundles detect the update — a git tag alone is not enough; a GitHub Release must exist. A missing/unreadable key (pre-versioning bundle) is treated as stale, so the update is offered rather than silently skipped; `update.rb` and the key first ship together, so a normal upgrade path never lacks it.
- **Updater uses `curl`** (system binary, handles TLS/redirects/proxies) rather than Ruby's `net/http`, and copies the release tarball over the bundle while skipping `.git`, `.idea`, `.claude`.
- **Auto-restart is decoupled**: the command runs as a child of MailMate, so quitting inline would kill it mid-flight. `relaunch_mailmate` spawns a **detached** watcher (own process group, IO to `/dev/null`) that polls `pgrep -x MailMate` until MailMate exits, then `open -a MailMate` — only afterwards does it tell MailMate to quit.
- AppleScript escaping: Uses `.inspect` on JSON to escape quotes
- OCR: Triggers only on blank PDFs (0 word count) and non-encrypted records
- Duplicates: Controlled by `delete_duplicate_record` and `move_to_trash` in user config
