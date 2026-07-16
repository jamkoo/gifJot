# GifJot

**Free Open-Source GIF Screen Recorder** is the working description for GifJot, a small native macOS menu-bar utility for turning a selected screen region into a paste-ready GIF.

> Trigger -> select -> record -> stop -> GIF copied

## Status

GifJot now contains an end-to-end macOS prototype: choose **Record GIF** from the menu bar, drag a region on one display, wait for the optional countdown, record, choose **Stop Recording**, and receive a looping GIF in `Downloads/GifJot`. The finished file is also copied to the clipboard when that setting is enabled.

The implementation is ready for its first macOS build and runtime pass, but that pass has not been completed yet. The code was prepared on Windows, where Xcode, ScreenCaptureKit behavior, signing, and physical multi-display behavior cannot be verified.

The prototype currently uses Apple's Image I/O encoder. That keeps the app dependency-free while GIF quality and file-size tradeoffs are measured before the final encoder and source license are selected.

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

## First test run

1. Build and run the **GifJot** scheme in Xcode.
2. Grant Screen Recording access when macOS asks, then quit and reopen GifJot if the app says a restart is required.
3. Choose **Record GIF** from the menu-bar menu.
4. Drag a region entirely on one display. Press Escape to cancel selection.
5. Choose **Stop Recording** from the menu-bar menu.
6. Confirm the GIF appears in `Downloads/GifJot`, loops at the expected speed, and pastes into another app.

Recordings automatically stop after two minutes. Frame processing uses a bounded queue; when the encoder cannot keep up, GifJot drops and reports frames instead of allowing capture memory to grow without limit. Temporary frame data is removed after success, cancellation, or failure, and abandoned sessions are removed on the next launch.

Debug builds also include isolated region-selection and five-second capture diagnostics in the menu. These are intended to make first-run permission, display-coordinate, and frame-delivery problems easier to separate from GIF encoding problems.

## Privacy

GifJot's core workflow is designed to work without network access. Captured content and temporary recording data stay on the user's Mac. Network features and telemetry are outside the MVP scope.

## Licensing status

The final license is intentionally deferred until the GIF encoder benchmark determines whether GifJot uses only Apple Image I/O or integrates a copyleft encoder. Until a `LICENSE` file is added, do not assume permission to redistribute or reuse the source.
