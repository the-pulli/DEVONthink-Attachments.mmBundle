#!/usr/bin/env ruby
# frozen_string_literal: true

require "json"
require "tmpdir"
require "fileutils"
require "open3"

# Self-updater for the DEVONthink Attachments MailMate bundle.
#
# Checks GitHub for the latest release, compares it with the version stored in
# the bundle's info.plist, and — after confirmation via an AppleScript dialog —
# downloads the release tarball and copies it over the installed bundle in place.
module Updater
  REPO = "the-pulli/DEVONthink-Attachments.mmBundle"
  DIALOG_TITLE = "DEVONthink Attachments"
  # Local dev checkouts (git, JetBrains, Claude) are never shipped in a release
  # tarball; skip them so a self-update can't clobber local-only state.
  SKIP_ENTRIES = %w[.git .idea .claude].freeze
  NOTES_LIMIT = 1500

  module_function

  def bundle_dir
    File.expand_path("../..", __dir__)
  end

  def info_plist
    File.join(bundle_dir, "info.plist")
  end

  # Reads the <key>version</key> string from info.plist without a plist gem.
  def current_version
    xml = File.read(info_plist)
    xml =~ %r{<key>version</key>\s*<string>(.*?)</string>}m
    Regexp.last_match(1)&.strip
  end

  # Fetches a URL with curl, which ships on every macOS and transparently handles
  # TLS, redirects (-L), and proxies. Returns the response body.
  def curl_get(url, *extra_args)
    out, err, status = Open3.capture3(
      "curl", "-fsSL", "--retry", "2",
      "-H", "User-Agent: DEVONthink-Attachments-Updater",
      *extra_args, url
    )
    raise "Download failed (#{err.strip.empty? ? "curl exit #{status.exitstatus}" : err.strip})" unless status.success?

    out
  end

  def latest_release
    body = curl_get("https://api.github.com/repos/#{REPO}/releases/latest",
                    "-H", "Accept: application/vnd.github+json")
    data = JSON.parse(body)
    {
      version: data.fetch("tag_name").sub(/\Av/, "").strip,
      notes: (data["body"] || "").gsub("\r\n", "\n").strip,
      tarball_url: data.fetch("tarball_url"),
    }
  end

  # Compares dotted version strings numerically (1.2.0 > 1.1.9, 1.10 > 1.2).
  # A nil/missing local version (e.g. a pre-versioning bundle with no <version>
  # key in info.plist) is treated as stale, so the update is offered — installing
  # it writes a plist that does carry the key. A nil latest means we couldn't read
  # the remote version, so we never claim an update is available.
  def newer?(latest, current)
    return false if latest.nil?
    return true if current.nil?

    to_parts = ->(v) { v.split(".").map { |p| p.to_i } }
    (to_parts.call(latest) <=> to_parts.call(current)) == 1
  end

  # Runs AppleScript, passing dynamic text through env vars so there is no string
  # escaping to get wrong. Returns [stdout, success?].
  def osascript(source, env = {})
    out, status = Open3.capture2(env, "osascript", "-e", source)
    [out.strip, status.success?]
  end

  def alert(message)
    osascript(<<~AS, "MM_UPD_TEXT" => message)
      display dialog (system attribute "MM_UPD_TEXT") buttons {"OK"} default button "OK" with title "#{DIALOG_TITLE}"
    AS
  end

  # Shows a two-button dialog and returns the label the user clicked, or "" if
  # they cancelled (Esc). Button labels are our own constants, so interpolating
  # them into the AppleScript source is safe; the message goes via env var.
  def ask(message, buttons, default_button)
    button_list = buttons.map { |b| %("#{b}") }.join(", ")
    out, ok = osascript(<<~AS, "MM_UPD_TEXT" => message)
      try
        return button returned of (display dialog (system attribute "MM_UPD_TEXT") buttons {#{button_list}} default button "#{default_button}" with title "#{DIALOG_TITLE}")
      on error number -128
        return ""
      end try
    AS
    ok ? out : ""
  end

  # Quits MailMate and relaunches it once it has fully exited.
  #
  # The command runs as a child of MailMate, so quitting would kill this process
  # mid-flight. Instead a detached watcher (own process group, no MailMate
  # parent) polls until MailMate is gone, then reopens it — surviving the quit.
  def relaunch_mailmate
    watcher = <<~SH
      n=0
      while /usr/bin/pgrep -x MailMate >/dev/null 2>&1; do
        sleep 0.5
        n=$((n + 1))
        [ "$n" -ge 120 ] && exit 0
      done
      /usr/bin/open -a MailMate
    SH
    pid = Process.spawn("/bin/bash", "-c", watcher,
                        pgroup: true, in: File::NULL, out: File::NULL, err: File::NULL)
    Process.detach(pid)
    osascript(%(tell application id "com.freron.MailMate" to quit))
  end

  # Downloads the release tarball and copies its contents over the bundle.
  def install(tarball_url)
    Dir.mktmpdir do |tmp|
      tarball = File.join(tmp, "release.tar.gz")
      curl_get(tarball_url, "-o", tarball)

      unless system("tar", "xzf", tarball, "-C", tmp)
        raise "Failed to extract release archive"
      end

      root = Dir.children(tmp)
                .map { |c| File.join(tmp, c) }
                .find { |p| File.directory?(p) }
      raise "Release archive has unexpected layout" unless root

      Dir.children(root).each do |entry|
        next if SKIP_ENTRIES.include?(entry)

        FileUtils.cp_r(File.join(root, entry), bundle_dir, remove_destination: true)
      end
    end
  end

  def run
    current = current_version
    release = latest_release
    current_display = current || "unknown"

    unless newer?(release[:version], current)
      alert("You're up to date.\n\nInstalled version: #{current_display}\nLatest release: #{release[:version]}")
      return
    end

    notes = release[:notes]
    notes = "#{notes[0, NOTES_LIMIT].rstrip}\n…" if notes.length > NOTES_LIMIT
    message = "An update is available.\n\n" \
              "Installed: #{current_display}\nLatest: #{release[:version]}\n\n" \
              "#{notes.empty? ? "" : "#{notes}\n\n"}" \
              "Update the bundle now?"

    return unless ask(message, ["Cancel", "Update"], "Update") == "Update"

    install(release[:tarball_url])

    restart = ask("Updated to #{release[:version]}.\n\nRestart MailMate now to apply the update?",
                  ["Later", "Restart"], "Restart")
    if restart == "Restart"
      relaunch_mailmate
    else
      alert("Update installed.\n\nQuit and reopen MailMate to apply it.")
    end
  rescue StandardError => e
    alert("Update failed.\n\n#{e.message}")
  end
end

Updater.run if __FILE__ == $PROGRAM_NAME
