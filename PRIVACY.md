# GifJot Privacy Statement

Last updated: 2026-07-24

GifJot is designed so its recording workflow works locally and offline. The
application does not require an account and does not contain upload, analytics,
advertising, telemetry, or crash-reporting services.

## Information GifJot processes

GifJot processes only the information needed to create a recording:

- Pixels from the screen region you select.
- Frame timestamps and non-content metadata such as dimensions and dropped-frame
  counts.
- Recording preferences stored in macOS `UserDefaults`.
- Temporary PNG frames in an application-controlled macOS temporary directory.
- The completed GIF saved to `~/GifJot` by default, or to the local folder you
  choose in Settings.
- The completed GIF's file URL when clipboard copy is enabled.
- The most recent completed GIF's local path in macOS `UserDefaults`, used to
  restore Open, Copy, and Reveal actions after relaunch.

Release builds do not intentionally persist raw screen frames after a recording
finishes.

## Screen Recording permission

macOS requires Screen Recording permission before GifJot can capture pixels.
GifJot uses ScreenCaptureKit to capture the display and region selected by the
user. It does not request Accessibility, microphone, camera, contacts, location,
or notification permission.

You can review or revoke Screen Recording access in **System Settings > Privacy
& Security > Screen & System Audio Recording**.

## Storage and retention

- Temporary recording frames are removed after successful export, cancellation,
  and failure.
- Abandoned temporary sessions and hidden export working files are removed the
  next time GifJot launches.
- Completed GIFs remain in the selected recording folder until you move or
  delete them.
- Preferences remain in macOS user defaults until they are reset or the app's
  data is removed.

Disk, operating-system, backup, synchronization, or clipboard tools outside
GifJot may retain copies according to their own behavior.

## Network activity and third parties

GifJot's application code does not intentionally make network requests. It uses
Apple system frameworks and has no third-party runtime dependency.

GitHub processes information when you visit this download repository or submit
an issue according to GitHub's own policies. That activity is separate from
running GifJot.

## Questions

For a privacy question that is not a vulnerability, email
[hi@gifjot.com](mailto:hi@gifjot.com) without including sensitive recordings
or personal information. Report vulnerabilities through the private process
described in [SECURITY.md](SECURITY.md).
