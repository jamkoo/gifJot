# Changelog

All notable changes to GifJot will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). GifJot intends to use [Semantic Versioning](https://semver.org/spec/v2.0.0.html) after the first tagged release.

## [Unreleased]

### Added

- Native macOS menu-bar application shell and typed settings.
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

### Changed

- Declared the project license as GNU AGPL version 3 or later.
- Refined the menu-bar panel, permission guidance, settings, and region selector around a compact native visual system.

### Security

- Documented private vulnerability reporting and prohibited sensitive content in public reports.

[Unreleased]: https://github.com/jamkoo/gifJot/commits/main
