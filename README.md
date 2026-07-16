# GifJot

[![macOS CI](https://github.com/jamkoo/gifJot/actions/workflows/macos-ci.yml/badge.svg)](https://github.com/jamkoo/gifJot/actions/workflows/macos-ci.yml)

GifJot is a free, open-source, native macOS menu-bar utility for turning a selected screen region into a local, paste-ready GIF.

> Record GIF -> select one-display region -> record -> stop -> save and copy

## Project status

GifJot is an early, unreleased prototype. The end-to-end workflow is implemented in source, but there is no signed or notarized public build yet. Xcode compilation, ScreenCaptureKit behavior, clipboard compatibility, performance, and multi-display geometry still require verification on real Macs before a release is declared ready.

The current implementation uses Apple Image I/O for GIF encoding and has no third-party runtime or package dependency.

## Current prototype

- Native SwiftUI and AppKit menu-bar application.
- Screen Recording permission guidance without Accessibility permission.
- One overlay per display with crosshair region selection and Escape cancellation.
- Single-display capture through ScreenCaptureKit.
- Configurable output width, frame rate, countdown, cursor visibility, and copy behavior.
- Menu-bar Record and Stop controls with a two-minute recording guardrail.
- Protocol-backed Image I/O GIF encoding with presentation-time-based frame delays.
- Bounded capture and processing queues that drop and report frames instead of growing memory without limit.
- Collision-safe saves to `~/Downloads/GifJot`.
- Optional clipboard copy as a GIF file URL.
- Temporary-frame cleanup after success, cancellation, failure, and the next launch.
- Deterministic tests for state transitions, coordinates, timing, sizing, settings, filenames, encoding, export, and cleanup.

## Product boundaries

The macOS MVP is intentionally narrow:

- Local-only operation with no accounts, uploads, telemetry, ads, or watermark.
- Silent GIF recording only.
- No editor, audio, webcam, annotations, cloud sharing, or additional export formats.
- No Accessibility permission.
- Windows work starts only after the macOS workflow is stable.

## Requirements

- macOS 14 or later
- Xcode 15 or later

## Build and test

The detected Xcode container is `apps/macos/GifJot.xcodeproj`. Its shared app/test scheme is `GifJot`.

Open the project in Xcode, select the **GifJot** scheme, and run. GifJot is an agent-style application, so it appears in the menu bar rather than the Dock.

To build without code signing:

```sh
xcodebuild \
  -project apps/macos/GifJot.xcodeproj \
  -scheme GifJot \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build
```

To run the test suite:

```sh
xcodebuild \
  -project apps/macos/GifJot.xcodeproj \
  -scheme GifJot \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test
```

Development builds require no repository secrets, signing certificates, or network service.

## First test run

1. Build and run the **GifJot** scheme in Xcode.
2. Grant Screen Recording access when macOS asks.
3. Quit and reopen GifJot if the permission panel says a restart is required.
4. Choose **Record GIF** from the menu-bar menu.
5. Drag a region entirely within one display. Press Escape to cancel selection.
6. Choose **Stop Recording** from the menu-bar menu.
7. Confirm the GIF appears in `~/Downloads/GifJot`, loops at the expected speed, and pastes into another application.

Debug builds also provide isolated region-selection and five-second frame-delivery diagnostics in the menu.

## Known limitations

- No global keyboard shortcut is implemented yet.
- No signed, notarized, packaged release is available yet.
- Image I/O output quality and file size have not completed the planned encoder benchmark.
- Physical testing is still required for Retina and external displays, negative display origins, permission changes, repeated recording, disk failures, and clipboard failures.
- The temporary bundle identifier must be confirmed before distribution.

## Community and policies

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing a change.
- Follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) in all project spaces.
- Read [PRIVACY.md](PRIVACY.md) for the app's local-data behavior.
- Report vulnerabilities according to [SECURITY.md](SECURITY.md), not through a public issue.
- User-visible changes are tracked in [CHANGELOG.md](CHANGELOG.md).

## License

Copyright (C) 2026 GifJot contributors.

GifJot is free software licensed under the **GNU Affero General Public License, version 3 or any later version** (`AGPL-3.0-or-later`). You may redistribute and modify it under those terms. GifJot is provided without warranty; see [LICENSE](LICENSE) for the complete license text.
