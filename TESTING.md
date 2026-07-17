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

Pushes to `main` run the same checks. A successful `main` macOS run also creates the downloadable test application, DMG, and checksums. Both workflows support manual dispatch for any pushed branch.

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
- Cursor on and off settings match the output.
- Original, 1280, 960, and 640 width settings produce correct aspect-preserving output.
- A static interval preserves elapsed time without redundant visible frames.
- The GIF loops, opens in common viewers, and pastes into at least Finder, a browser, and a messaging or documentation application.
- Repeated recordings use collision-safe filenames and keep the latest valid output available.
- Cancellation and failure remove temporary frames and hidden export working files.

### Failure and endurance coverage

- Unavailable or read-only destination reports failure and leaves no partial final GIF.
- Low-disk or write failure does not overwrite an existing GIF.
- Clipboard failure still preserves the saved GIF and reports the copy problem.
- Repeated short recordings do not leave capture active, orphan overlays, or stale HUDs.
- A longer recording keeps memory bounded and reports dropped frames rather than growing without limit.

### Installation and release artifact

- Download the artifact from a clean browser session and verify `SHA256SUMS.txt`.
- Install from the DMG on a Mac without Xcode.
- Confirm the documented Control-click Open or Open Anyway path for the current ad-hoc-signed build.
- Confirm the app launches from `/Applications`, requests only Screen Recording, records, saves, and copies.
- Repeat clean-install testing with normal double-click launch once Developer ID signing and notarization are added.

## Reporting verification

Pull requests and release notes must state exactly which Windows checks, macOS CI jobs, and manual rows passed. Use **not run** or **unverified** for anything that was not actually exercised.
