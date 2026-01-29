# Upgrade Guide

Maintainer: PuLLi

## Upgrading from 0.2.0 to v1.0.0

### What Changed

| 0.2.0 | v1.0.0 |
|-------|--------|
| Custom rules in `Support/bin/rule.rb` inside bundle | Custom rules in `~/Library/Application Support/MailMate/DEVONthink Attachments Config/rules.rb` |
| Ruby class with constants | Simple Ruby hash |
| Edit bundle files directly | Bundle can be replaced without losing config |
| Complex Ruby version detection | Simple `/usr/bin/env ruby` |
| 5 Ruby files | 2 Ruby files |

### Migration Steps

#### If you have custom rules in `rule.rb`:

1. **Before updating**, open your old `rule.rb` and note your customizations:

   ```ruby
   # Old format (0.2.0) - in Support/bin/rule.rb
   class Rule
     RULES = {
       filename_reject!: /your-custom-pattern/i,
       mime_reject!: /pgp-encrypted/i,
       mime_select!: /application/i
     }.freeze
     DELETE_DUPLICATE_RECORD = true
     MOVE_TO_TRASH = false  # example: you changed this
   end
   ```

2. **Update the bundle** (replace files or `git pull`)

3. **Open new config** via MailMate: Command → Attachment Rules... (Ctrl+R)

   This creates `~/Library/Application Support/MailMate/DEVONthink Attachments Config/rules.rb`

4. **Convert your customizations** to the new format:

   ```ruby
   # New format (v1.0.0) - only include what you changed
   {
     rules: {
       filename_reject!: /your-custom-pattern/i,
     },
     move_to_trash: false,
   }
   ```

   **Note:** You only need to include settings that differ from defaults. The defaults are:
   ```ruby
   rules: {
     filename_reject!: /signature|msg|encrypted|openpgp|smime\.p7s|asc/i,
     mime_reject!: /pgp-encrypted/i,
     mime_select!: /application/i
   },
   delete_duplicate_record: true,
   move_to_trash: true
   ```

#### If you never customized rules:

No action needed. Just update the bundle.

### Quick Reference: Old vs New Format

**Old (0.2.0):**
```ruby
module DEVONthink
  class Rule
    RULES = {
      filename_reject!: /pattern/i,
    }.freeze
    DELETE_DUPLICATE_RECORD = true
    MOVE_TO_TRASH = true
  end
end
```

**New (v1.0.0):**
```ruby
{
  rules: {
    filename_reject!: /pattern/i,
  },
  delete_duplicate_record: true,
  move_to_trash: true,
}
```

### Benefits of v1.0.0

- **Update-safe**: Config lives outside bundle, never lost on update
- **Simpler config**: Just a hash, no Ruby classes needed
- **Merge behavior**: Only specify overrides, defaults auto-apply
- **Less code**: Easier to maintain and understand
