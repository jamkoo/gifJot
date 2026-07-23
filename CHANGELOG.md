# Changelog

All notable changes to GifJot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). GifJot intends to use [Semantic Versioning](https://semver.org/spec/v2.0.0.html) after the first tagged release.

## [Unreleased]

### Added

- Native macOS menu-bar application shell and typed settings.
- Configurable recording-folder selection in Settings.
- Screen Recording permission guidance and development-only capture diagnostics.
- Single-display region-selection overlays with coordinate-conversion tests.
- Bounded ScreenCaptureKit frame processing and temporary-frame storage.
- Protocol-backed Apple Image I/O GIF encoding.
- Collision-safe local export and optional clipboard copy.
- End-to-end Record and Stop workflow with cancellation and failure recovery.
- Global `Option-Command-G` recording shortcut without an Accessibility permission requirement.
- Non-captured region border and detached HUD for countdown, recording, processing, and completion states.
- Automatic exact duplicate-frame coalescing with preserved recording timing.
- Deterministic unit and integration tests for core recording logic.
- Public privacy, contribution, conduct, security, and change-log policies.
- Structured GitHub issue forms, pull-request template, and unsigned macOS CI.
- Automatic ad-hoc-signed `.app` and `.dmg` test packages from successful `main` builds.
- Windows repository preflight, shared cross-platform Swift tests, Windows CI, and a physical-Mac verification matrix.
- Universal Apple silicon and Intel test packages with architecture and minimum-version verification.

### Changed

- Declared the project license as GNU AGPL version 3 or later.
- Changed the default recording folder from `~/Downloads/GifJot` to `~/GifJot`.
- Rebuilt the menu-bar panel, permission guidance, settings, region selector, and recording HUD around the Pocket Capture Camera visual system.
- Introduced an adaptive optical-ivory camera body, circular signal shutter, graphite status well, open viewfinder corners, and measured state readouts.
- Added an explicit region-ready step with a low-footprint single-row controller, hover help, frame presets (including Full Screen), output-size choices, cursor visibility, direct Settings access, and a terminal-right cancellation control before capture begins.
- The armed capture frame can now be moved or resized within its original display before recording begins.
- Hardened the first-run permission relaunch, capture startup feedback, failure visibility, preset behavior, recent-output recovery, and abandoned-export cleanup.

### Security

- Documented private vulnerability reporting and prohibited sensitive content in public reports.

[Unreleased]: https://github.com/jamkoo/gifJot/commits/main
