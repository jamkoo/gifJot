# GifJot Privacy Statement

Last updated: 2026-08-02

GifJot is designed so its core capture workflow works locally and offline. The
application does not require an account and does not contain upload, analytics,
advertising, telemetry, or crash-reporting services.

## Information GifJot processes

GifJot processes only the information needed to create the GIF or PNG you
request:

- Pixels from the screen region you select.
- GIF frame timestamps and non-content metadata such as dimensions and
  dropped-frame counts.
- Capture and shortcut preferences stored in macOS `UserDefaults`.
- Temporary PNG frames for GIF recording in an application-controlled
  directory under the macOS temporary directory.
- Annotations you add in the local Jot canvas. GifJot rasterizes them into the
  exported GIF or PNG and does not upload them.
- Completed GIFs and PNGs saved to `~/GifJot` by default, or to the local folder
  you choose in Settings.
- The completed output's file or image representations when clipboard copy is
  enabled.
- The most recent completed capture's local path in macOS `UserDefaults`, used
  to restore Open, Copy, and Reveal actions after relaunch.
- The installed app version and signed release-feed response used to determine
  whether an update is available.

Release builds do not intentionally persist raw screen frames after a recording
finishes.

## Screen Recording permission

macOS requires Screen Recording permission before GifJot can capture pixels for
either a GIF or PNG. GifJot uses ScreenCaptureKit to capture the display and
region selected by the user and excludes the GifJot application from the
production capture filter. GifJot does not request Accessibility, microphone,
camera, contacts, or location permission.

You can review or revoke Screen Recording access in **System Settings > Privacy
& Security > Screen & System Audio Recording**. Revoking permission prevents
GifJot from recording until access is restored.

If macOS keeps a stale Screen Recording decision after GifJot's signing identity
changes, GifJot can offer an explicit repair action. That action removes only
the Screen Recording decision for GifJot, then reopens the app so macOS can
request permission again. It does not reset privacy decisions for other apps or
services.

GifJot requests provisional notification authorization for update notices.
Provisional notices are quiet: macOS places them in Notification Center without
a sound or banner and lets you keep or turn them off. GifJot sends a local
notice only when a newer signed release is found.

## Storage and retention

- Temporary recording frames are removed after successful export, cancellation,
  and failure.
- Abandoned temporary recording sessions are removed the next time GifJot
  launches.
- Abandoned hidden export working files in the selected capture folder are
  removed the next time GifJot launches.
- Completed GIFs and PNGs remain in the selected capture folder until you move
  or delete them.
- The recent-output path remains in macOS `UserDefaults` while that output
  exists and is discarded when GifJot next launches after the file is removed.
- Clipboard image and file representations remain available until another
  application replaces the clipboard contents.
- Preferences remain in macOS user defaults until they are reset or the
  application's data is removed.

Disk, operating-system, backup, synchronization, or clipboard tools outside
GifJot may retain copies according to their own behavior.

## Network activity and third parties

GifJot checks an HTTPS release feed hosted by GitHub Releases at most once every
24 hours and whenever you choose **Check for Updates…**. The app uses Sparkle to
verify the feed and update archive with GifJot's EdDSA signing key before
installation. System-profile reporting is disabled, and GifJot does not add an
account, install identifier, capture metadata, or screen content to update
requests.

If you choose **Update**, Sparkle downloads the signed app archive and release
notes from GitHub Releases. Standard network information such as your IP
address and HTTP request metadata is necessarily visible to GitHub. GitHub
processes that information under its own policies. No capture pixels,
annotations, filenames, or usage events are uploaded.

GifJot uses Apple system frameworks including AppKit, SwiftUI,
ScreenCaptureKit, Core Image, Image I/O, User Notifications, and Uniform Type
Identifiers. Sparkle is the app's third-party runtime dependency and is used
only for signed software updates.

GitHub also processes information when you visit this download repository or
submit an issue. That activity is separate from running GifJot.

## Website analytics

The GifJot website uses Vercel Web Analytics to measure aggregate page views
and a small set of explicit website actions: viewing the product examples,
selecting a download link, and selecting the feedback email link. Website
analytics are separate from the GifJot app and never receive screen captures,
annotations, filenames, capture settings, or in-app usage events.

As with ordinary website hosting, Vercel and GitHub can receive standard
network information such as an IP address, browser request headers, and the
requested page or download. The GifJot app does not send an installation
identifier or connect website activity to captures created on the Mac.

## Logs

GifJot may write local operating-system logs for diagnostics. Logging is
limited to privacy-safe metadata such as dimensions, frame counts, timestamps,
and error descriptions. GifJot must not log captured pixels or deliberately log
user-created recording filenames.

## Questions

For a privacy question that is not a vulnerability, email
[hi@gifjot.com](mailto:hi@gifjot.com) without including sensitive recordings
or personal information. Report vulnerabilities through the private process
described in [SECURITY.md](SECURITY.md).
