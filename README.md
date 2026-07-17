# GifJot

[![macOS CI](https://github.com/jamkoo/gifJot/actions/workflows/macos-ci.yml/badge.svg)](https://github.com/jamkoo/gifJot/actions/workflows/macos-ci.yml)
[![Windows Checks](https://github.com/jamkoo/gifJot/actions/workflows/windows-checks.yml/badge.svg)](https://github.com/jamkoo/gifJot/actions/workflows/windows-checks.yml)

GifJot is a free, open-source, native macOS menu-bar utility for turning a selected screen region into a local, paste-ready GIF.

> Record Area -> select one-display region -> record -> stop -> save and copy

## Project status

GifJot is an early, unreleased prototype. The end-to-end workflow is implemented in source, and successful `main` builds provide an ad-hoc-signed test app and DMG. There is no Developer ID-signed or notarized public release yet. ScreenCaptureKit behavior, clipboard compatibility, performance, and multi-display geometry still require verification on real Macs before a release is declared ready.

The current implementation uses Apple Image I/O for GIF encoding and has no third-party runtime or package dependency.

Windows can run repository preflight checks and a shared package of platform-neutral Swift tests. macOS CI remains authoritative for the native application build and complete Xcode test target, and physical Mac testing remains required for capture and permission behavior.

## Current prototype

- Native SwiftUI and AppKit menu-bar application.
- Pocket Capture Camera interface with an adaptive optical body, signal shutter, graphite status well, and precise viewfinder selection.
- Low-footprint region-ready controller beside the selection with an explicit shutter, output-size, cursor, cancel controls, and hover help.
- Screen Recording permission guidance without Accessibility permission.
- One overlay per display with crosshair region selection and Escape cancellation.
- Single-display capture through ScreenCaptureKit.
- Configurable output width, frame rate, countdown, cursor visibility, and copy behavior.
- Menu-bar controls plus a global `Option-Command-G` shortcut that does not require Accessibility permission.
- A non-captured recording border and detached countdown, elapsed-time, Stop, processing, and completion HUD.
- Protocol-backed Image I/O GIF encoding with presentation-time-based frame delays.
- Automatic exact-frame coalescing that turns unchanged screen periods into longer frame delays instead of redundant GIF frames.
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

## Test a build without Xcode

Testers need macOS 14 or later and do not need Xcode.

1. Open the [macOS CI workflow](https://github.com/jamkoo/gifJot/actions/workflows/macos-ci.yml).
2. Choose the newest successful run for `main`.
3. Download the `GifJot-macOS-Test-*` artifact from the run's **Artifacts** section and unzip the download.
4. Open `GifJot-Test.dmg`, then drag **GifJot** to **Applications**.
5. On first launch, Control-click **GifJot** in Applications and choose **Open**. If macOS still blocks it, open **System Settings > Privacy & Security** and choose **Open Anyway** for GifJot.
6. Grant Screen Recording access when requested, then quit and reopen GifJot if macOS requires it.

These test builds are ad-hoc signed for bundle integrity but are not signed with an Apple Developer ID or notarized. Only download them from this repository. Do not disable Gatekeeper. A future public release will be Developer ID-signed and notarized so it opens through the normal double-click flow.

Each artifact also contains `GifJot-Test.app.zip` and `SHA256SUMS.txt`. The DMG is the simplest installation path; the ZIP is provided as a fallback.

## User requirements

- macOS 14 or later

## Developer requirements

- Native application development: macOS 14 or later and Xcode 15 or later.
- Windows preflight: Windows PowerShell 5.1 or PowerShell 7, Git, and optionally the official Swift toolchain for shared core tests.

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

### Windows preflight and shared core tests

Windows cannot compile the macOS application, but it can validate repository integrity and run platform-neutral production logic through Swift Package Manager:

```powershell
./scripts/check-windows.ps1
```

Install Swift and require the complete Windows test layer:

```powershell
winget install --id Swift.Toolchain --exact --source winget
./scripts/check-windows.ps1 -RequireSwift
```

Open a new PowerShell session if `swift` is not found immediately after installation. See [TESTING.md](TESTING.md) for the CI layers and required physical-Mac test matrix.

## First source test run

1. Build and run the **GifJot** scheme in Xcode.
2. Grant Screen Recording access when macOS asks.
3. If prompted, choose **Quit and Reopen GifJot**. Confirm the menu-bar icon returns and the panel says **Ready to Record**.
4. Choose **Start Recording**, choose **Record Area** from the menu-bar panel, or press `Option-Command-G`.
5. Drag a region entirely within one display. Press Escape to cancel selection.
6. Confirm GifJot does not record yet. Drag inside the orange frame to reposition it, or drag an edge or corner to resize it. Then use the nearby controller to choose output size and whether to include the cursor.
7. Press **Record** in the nearby controller, use the menu-bar panel, or press `Option-Command-G` again.
8. Confirm the detached HUD changes from countdown to **Starting recording** and then **Recording**.
9. Stop from the detached recording HUD, the menu-bar panel, or `Option-Command-G`.
10. Confirm the GIF appears in `~/Downloads/GifJot`, loops at the expected speed, and pastes into another application.
11. Start and cancel a second recording, then confirm the previous GIF remains available through **Open**, **Copy**, and **Reveal** in the menu-bar panel.

Debug builds also provide isolated region-selection and five-second frame-delivery diagnostics in the menu.

## Known limitations

- The global shortcut is fixed to `Option-Command-G` and is not configurable yet.
- Downloadable test builds are ad-hoc signed and packaged, but no Developer ID-signed and notarized release is available yet.
- Image I/O output quality and file size have not completed the planned encoder benchmark.
- Physical testing is still required for Retina and external displays, negative display origins, permission changes, repeated recording, disk failures, and clipboard failures.
- The temporary bundle identifier must be confirmed before distribution.

## Community and policies

- Read [CONTRIBUTING.md](CONTRIBUTING.md) before proposing a change.
- Follow [TESTING.md](TESTING.md) when reporting automated or manual verification.
- Follow [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) in all project spaces.
- Read [PRIVACY.md](PRIVACY.md) for the app's local-data behavior.
- Report vulnerabilities according to [SECURITY.md](SECURITY.md), not through a public issue.
- User-visible changes are tracked in [CHANGELOG.md](CHANGELOG.md).

## License

Copyright (C) 2026 GifJot contributors.

GifJot is free software licensed under the **GNU Affero General Public License, version 3 or any later version** (`AGPL-3.0-or-later`). You may redistribute and modify it under those terms. GifJot is provided without warranty; see [LICENSE](LICENSE) for the complete license text.
