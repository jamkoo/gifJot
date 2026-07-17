# Contributing to GifJot

Thank you for helping make GifJot a fast, private, dependable macOS GIF recorder.

## Before you start

- Search existing issues before opening a new report or proposal.
- Use the structured bug or feature form when opening an issue.
- Discuss material architecture, dependency, privacy, permission, or product-scope changes before implementing them.
- Do not include screen recordings, logs, paths, or screenshots containing private information.
- Security vulnerabilities must follow [SECURITY.md](SECURITY.md), not the public issue tracker.

## Scope

Changes should improve trigger-to-clipboard speed, output usefulness, reliability, privacy, or maintainability of the current native macOS workflow.

The MVP does not include accounts, uploads, telemetry, ads, watermarks, audio, webcam capture, an editor, annotations, cross-display regions, or additional export formats. Windows implementation is deferred until the macOS workflow is stable.

Do not introduce Electron, Tauri, Flutter, a browser runtime, a custom Rust shared core, broad Accessibility permission, or a new dependency without prior agreement and documented privacy, maintenance, size, and license analysis.

## Development setup

Requirements:

- macOS 14 or later and Xcode 15 or later for native app development.
- Windows PowerShell 5.1 or PowerShell 7 for the Windows preflight.
- The official Swift for Windows toolchain to run shared core tests on Windows.
- Git on every platform.

Clone the repository and open the detected project:

```sh
git clone https://github.com/jamkoo/gifJot.git
cd gifJot
open apps/macos/GifJot.xcodeproj
```

Use the shared **GifJot** scheme. The scheme builds the `GifJot` application target and runs the `GifJotTests` unit-test target.

Build and test without signing:

```sh
xcodebuild \
  -project apps/macos/GifJot.xcodeproj \
  -scheme GifJot \
  -configuration Debug \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean test
```

Do not commit signing identities, certificates, provisioning profiles, credentials, local `.xcconfig` files, or notarization material.

On Windows, install Swift and run the shared checks from PowerShell:

```powershell
winget install --id Swift.Toolchain --exact --source winget
./scripts/check-windows.ps1 -RequireSwift
```

These checks do not compile or run the macOS application. Follow [TESTING.md](TESTING.md) for the macOS CI and physical-Mac gates.

## Making a change

1. Fork the repository or create a focused branch.
2. Keep the change small and preserve the existing component boundaries.
3. Add or update deterministic tests for changed logic.
4. Keep image conversion, disk work, and encoding off the UI thread and ScreenCaptureKit callback.
5. Keep frame queues bounded and clean temporary files on success, cancellation, failure, and next launch.
6. Update `CHANGELOG.md` for a user-visible or contributor-visible change.
7. Run the available tests and describe exactly what was and was not verified.

Use clear commit messages written in the imperative mood. Avoid mixing unrelated cleanup with functional changes.

## Testing expectations

At minimum, a pull request should pass the unsigned Xcode build and unit tests on macOS CI.

Pull requests also run the Windows repository preflight and shared Swift package tests. Run them locally when working from Windows, but do not describe them as an AppKit, SwiftUI, ScreenCaptureKit, signing, or runtime validation.

Changes involving capture, permission, displays, region geometry, cursor behavior, clipboard handling, or output quality also require relevant manual Mac testing. Report the hardware, macOS version, display arrangement, settings, and observed result without exposing sensitive content.

CI compilation does not replace physical testing for:

- Permission not requested, granted, denied, revoked, and restart-required states.
- Internal Retina and external 1x/2x displays.
- Displays arranged left, right, and above the primary display.
- Cancellation and repeated recordings.
- Disk-full, unavailable destination, and clipboard failure paths.
- Memory behavior during longer recordings.

## Pull requests

Complete the pull-request template. Include:

- The problem and the narrow solution.
- Related issue links.
- Tests run and results.
- Manual Mac coverage or a clear statement that it remains unverified.
- Privacy, permission, dependency, and license impact.
- Screenshots only when useful and fully scrubbed of private information.

Maintainers may decline changes that expand scope without improving the core workflow or that weaken privacy, permission, queue-bounding, cleanup, or licensing guarantees.

## Licensing contributions

GifJot is licensed under `AGPL-3.0-or-later`. By submitting a contribution, you agree that your contribution is licensed under the same terms and that you have the right to provide it. Preserve third-party copyright and license notices and identify any copied or adapted material in the pull request.

## Conduct

Participation in this project is governed by [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
