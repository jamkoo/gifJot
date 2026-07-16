# GifJot

**Free Open-Source GIF Screen Recorder** is the working description for GifJot, a small native macOS menu-bar utility for turning a selected screen region into a paste-ready GIF.

> Trigger -> select -> record -> stop -> GIF copied

## Status

GifJot is in early development. The repository currently contains the native menu-bar shell, typed recording preferences, and the recording lifecycle state machine. Screen capture and GIF encoding are not implemented yet.

## Product boundaries

- macOS first, with Windows considered after the Mac workflow is stable.
- Native SwiftUI and AppKit UI.
- ScreenCaptureKit for capture.
- Local-only operation with no accounts, uploads, telemetry, ads, or watermark.
- Silent GIF recording only for the MVP.
- No editor, audio capture, or additional export formats in the MVP.
- No Accessibility permission in the MVP.

## Requirements

- macOS 14 or later
- Xcode 15 or later

## Build and test

Open `apps/macos/GifJot.xcodeproj` in Xcode, select the **GifJot** scheme, and run the app. GifJot is an agent-style app, so it appears in the menu bar instead of the Dock.

Tests can also be run from Terminal:

```sh
xcodebuild \
  -project apps/macos/GifJot.xcodeproj \
  -scheme GifJot \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

The repository does not require secrets, signing certificates, or network services for development builds.

## Privacy

GifJot's core workflow is designed to work without network access. Captured content and temporary recording data stay on the user's Mac. Network features and telemetry are outside the MVP scope.

## Licensing status

The final license is intentionally deferred until the GIF encoder benchmark determines whether GifJot uses only Apple Image I/O or integrates a copyleft encoder. Until a `LICENSE` file is added, do not assume permission to redistribute or reuse the source.
