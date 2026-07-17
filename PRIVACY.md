# GifJot Privacy Statement

Last updated: 2026-07-17

GifJot is designed so its core recording workflow works locally and offline. The application does not require an account and does not contain upload, analytics, advertising, telemetry, or crash-reporting services.

## Information GifJot processes

GifJot processes only the information needed to create a recording:

- Pixels from the screen region you select.
- Frame timestamps and non-content metadata such as dimensions and dropped-frame counts.
- Recording preferences stored in macOS `UserDefaults`.
- Temporary PNG frames in an application-controlled directory under the macOS temporary directory.
- The completed GIF saved to `~/Downloads/GifJot`.
- The completed GIF's file URL when clipboard copy is enabled.
- The most recent completed GIF's local path in macOS `UserDefaults`, used to restore Open, Copy, and Reveal actions after relaunch.

Release builds do not intentionally persist raw screen frames after a recording finishes. Debug builds include an explicit five-second ScreenCaptureKit diagnostic that reports frame metadata without intentionally saving captured pixels.

## Screen Recording permission

macOS requires Screen Recording permission before GifJot can capture pixels. GifJot uses ScreenCaptureKit to capture the display and region selected by the user and excludes the GifJot application from the production capture filter. GifJot does not request Accessibility, microphone, camera, contacts, location, or notification permission for the current prototype.

Granting Screen Recording permission is controlled by macOS. You can review or revoke it in **System Settings > Privacy & Security > Screen & System Audio Recording**. Revoking permission prevents GifJot from recording until access is restored.

## Storage and retention

- Temporary recording frames are removed after successful export, cancellation, and failure.
- Abandoned temporary recording sessions are removed the next time GifJot launches.
- Abandoned hidden export working files in `~/Downloads/GifJot` are removed the next time GifJot launches.
- Completed GIFs remain in `~/Downloads/GifJot` until you move or delete them.
- The recent-output path remains in macOS `UserDefaults` while that GIF exists and is discarded when GifJot next launches after the file is removed.
- The clipboard file URL remains available until another application replaces the clipboard contents.
- Preferences remain in macOS user defaults until they are reset or the application's data is removed.

Disk, operating-system, backup, synchronization, or clipboard tools outside GifJot may retain copies according to their own behavior.

## Network activity and third parties

GifJot's application code does not intentionally make network requests. It uses Apple system frameworks, including AppKit, SwiftUI, ScreenCaptureKit, Core Image, Image I/O, and Uniform Type Identifiers. The current project has no third-party runtime or package dependency.

GitHub processes information when you visit or contribute to this source repository according to GitHub's own policies. That repository activity is separate from running the GifJot application.

## Logs

GifJot may write local operating-system logs for diagnostics. Logging is limited to privacy-safe metadata such as dimensions, frame counts, timestamps, and error descriptions. GifJot must not log captured pixels or deliberately log user-created recording filenames.

## Changes and questions

Material privacy changes will be documented in this file and in the change log. For a privacy question that is not a vulnerability, open a GitHub issue without including sensitive recordings or personal information. Report security or privacy vulnerabilities through the private process in [SECURITY.md](SECURITY.md).
