# Testing GifJot

GifJot uses layered checks because Windows cannot build or run Apple frameworks. Passing a lower layer never replaces the layers above it.

## 1. Windows preflight

Run the repository and Xcode-project checks from PowerShell:

```powershell
./scripts/check-windows.ps1
```

The script checks whitespace, merge markers, the public-repository boundary, and whether tracked Swift files agree with the Xcode Sources phase. It runs the shared Swift tests when the Swift toolchain is available.

Install the official Swift toolchain and Microsoft C++ Build Tools through Windows Package Manager:

```powershell
winget install --id Swift.Toolchain --exact --source winget
winget install --id Microsoft.VisualStudio.2022.BuildTools --exact
```

In the Visual Studio Installer, select **Desktop development with C++** for Build Tools. This installation requires Windows administrator approval. Open a new PowerShell session after installation, then require the complete Windows check:

```powershell
./scripts/check-windows.ps1 -RequireSwift
```

The root `Package.swift` reuses production source and XCTest files from the macOS application. It covers platform-neutral recording states, GIF frame timing, collision-safe filenames and exports, abandoned-export cleanup, and recent-output persistence. It does not create a separate Windows implementation of GifJot.

## 2. Automated CI

Every pull request runs two independent workflows:

- **Windows Checks** runs the PowerShell preflight and shared Swift package tests on Windows.
- **macOS CI** runs the shared Swift package tests, lists the Xcode project, builds the unsigned application, and runs the complete Xcode test target on macOS.

Pushes to `main` run the same checks. A successful `main` macOS run also creates the downloadable universal test application, DMG, checksums, and build information for Apple silicon and Intel Macs. CI fails packaging unless the executable contains both `arm64` and `x86_64` slices and declares macOS 14.0 as its minimum version. Both workflows support manual dispatch for any pushed branch.

macOS CI is the compile and unit-test authority for AppKit, SwiftUI, Carbon, Core Graphics, Image I/O, and ScreenCaptureKit code. CI still cannot prove physical display, permission, clipboard, or Gatekeeper behavior.

## 3. Manual Mac test gate

Record the Mac model, processor, macOS version, GifJot commit, display arrangement, and result for each applicable row. Use content created specifically for testing so screenshots and GIFs do not expose private information.

### Permission lifecycle

- Fresh install shows permission guidance before recording.
- Granting Screen Recording access offers Quit and Reopen.
- Relaunch returns to the ready state and Start Recording opens selection.
- Denial and later approval through System Settings recover cleanly.
- Revoking permission while GifJot is installed produces a clear failure.
- No Accessibility permission is requested.

### Displays and selection

- Internal Retina display records the selected pixels at expected dimensions.
- External 1x and 2x displays record the correct region.
- Displays positioned left, right, and above the primary display work, including negative global origins.
- A selection cannot span displays.
- Escape cancels selection without leaving overlays behind.
- The armed frame can be moved and resized without leaving its display.
- Full Screen, 16:9, 4:3, and 1:1 frame presets remain on the selected display.
- GifJot's border, controller, HUD, and menu UI are absent from the GIF.

### Recording and output

- Menu action and `Option-Command-G` both start, confirm, stop, and cancel at the correct states.
- Countdown, Starting Recording, Recording, Processing, and Complete states appear in order.
- Cursor and countdown state are visible on the ready inspector before recording begins.
- Cursor on and off settings match the output.
- Original, 1280, 960, and 640 width settings produce correct aspect-preserving output.
- A static interval preserves elapsed time without redundant visible frames.
- The GIF loops, opens in common viewers, and pastes into at least Finder, a browser, and a messaging or documentation application.
- Repeated recordings use collision-safe filenames and keep the latest valid output available.
- Cancellation and failure remove temporary frames and hidden export working files.

### Accessibility and appearance

- VoiceOver reaches the menu, selection, ready inspector, recording controls, result, and failure recovery in a logical order.
- VoiceOver frame actions move and resize the region and announce updated output dimensions.
- Pointer-only frame hit areas are not announced as unusable buttons.
- The complete flow works keyboard-only, including retry, dismiss, and focus restoration after terminal states.
- The largest configured macOS text size does not clip HUD, permission, popover, or Settings content.
- Light and Dark appearances preserve hierarchy and AA text contrast.
- Increase Contrast and Reduce Transparency preserve visible boundaries and legibility.
- Reduce Motion removes nonessential fades without hiding state changes.

### Failure and endurance coverage

- Unavailable or read-only destination reports failure and leaves no partial final GIF.
- Low-disk or write failure does not overwrite an existing GIF.
- Clipboard failure still preserves the saved GIF and reports the copy problem.
- Recording failure remains visible until the tester chooses Retry, Dismiss, or Escape.
- Repeated short recordings do not leave capture active, orphan overlays, or stale HUDs.
- A longer recording keeps memory bounded and reports dropped frames rather than growing without limit.

### Installation and release artifact

- Download the artifact from a clean browser session and verify `SHA256SUMS.txt`.
- Confirm `BUILD-INFO.txt` lists both `arm64` and `x86_64`, and `lipo -archs /Applications/GifJot.app/Contents/MacOS/GifJot` reports both architectures after installation.
- Install from the DMG on a Mac without Xcode.
- Confirm the documented Control-click Open or Open Anyway path for the current ad-hoc-signed build.
- Confirm the app launches from `/Applications`, requests only Screen Recording, records, saves, and copies.
- Repeat clean-install testing with normal double-click launch once Developer ID signing and notarization are added.

## Debug live-recording smoke test

For repeated local testing on one Mac, install the app with the stable local
development identity:

```sh
./scripts/install-macos-local.sh
```

The script requires a valid `GifJot Local Development` code-signing identity in
the login keychain. It binds the installed app's designated requirement to both
`com.gifjot.GifJot` and that certificate, verifies the signature before
installation, preserves the previous app in `/tmp`, and launches the new build.
The certificate and private key remain local to the Mac and are not repository
assets. The first transition from an ad-hoc build requires Screen Recording
approval once; later builds signed by this identity should retain it.

After granting Screen Recording access to a running Debug build, exercise the
native capture, frame pipeline, GIF encoder, file exporter, and clipboard
writer without automating macOS input:

```sh
swift -e 'import Foundation; DistributedNotificationCenter.default().postNotificationName(Notification.Name("com.gifjot.debug.runRecordingSmokeTest"), object: nil)'
```

The test records the centered 640-by-360-point region of the main display for
two seconds. Put non-sensitive test content in that region before triggering
it. Success writes a GIF to `~/GifJot` by default, copies its file URL, and logs
`GIFJOT_SMOKE_TEST_PASS`. Release builds ignore this notification.

## Reporting verification

Pull requests and release notes must state exactly which Windows checks, macOS CI jobs, and manual rows passed. Use **not run** or **unverified** for anything that was not actually exercised.

For a Developer ID-signed release candidate, copy
[`RELEASE_TEST_REPORT_TEMPLATE.md`](RELEASE_TEST_REPORT_TEMPLATE.md), record
each physical-Mac result, and retain the completed report with the release
artifacts. No required `unverified` or `fail` row may remain when declaring a
normal-user test release ready.
