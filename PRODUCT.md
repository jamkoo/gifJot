# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

The launch audience is Mac-based indie software builders, product designers,
technical writers, support specialists, and DevRel practitioners who repeatedly
need to show a visual bug, feature, or workflow in an asynchronous message or
document. This audience is an initial distribution hypothesis to validate with
the first 25 users.

## Product Purpose

GifJot is a lightweight native macOS menu-bar app that turns a selected screen
region into a paste-ready GIF. The product exists to collapse a common
communication task into a short loop: choose an area, record a few seconds,
stop, and paste.

Success means a new user can understand the workflow immediately, create a GIF
for a real task, and return to use GifJot again without being prompted.

## Positioning

GifJot combines a deliberately small capture workflow with local-only
processing. It requires no account, performs no uploads, and produces an
unwatermarked file that is ready to paste.

## Operating Context

GifJot lives in the macOS menu bar and is invoked either from its menu or with
the Option-Command-G shortcut. Typical outputs are pasted into bug reports,
product updates, support replies, documentation, and team messages.

The public website is a persuasion and download surface. The app binary remains
hosted in the public GitHub Releases repository.

## Capabilities and Constraints

- Records one user-selected screen region.
- Saves completed GIFs locally to `~/GifJot` by default or a chosen folder.
- Can copy the completed GIF to the clipboard.
- Supports configurable output size, frame rate, countdown, pointer visibility,
  save location, and global shortcut.
- Requires macOS 14 Sonoma or later and Screen Recording permission.
- Supports Apple silicon and Intel Macs.
- The public build is signed with an Apple Developer ID and notarized by Apple.
- The app has no accounts, uploads, telemetry, advertising, or watermarks.
- GifJot is free proprietary software; the public repository contains
  documentation and compiled downloads rather than source code.
- Website analytics may measure aggregate visits and explicit website actions.
  Analytics must never be described as app telemetry.

## Brand Commitments

- Product name: GifJot.
- Primary contact: hi@gifjot.com.
- The existing app icon and capture mark are authoritative brand assets.
- Canvas Indigo (`#6758E8`) is the product signal color.
- The voice is direct, practical, calm, and specific. Avoid hype, inflated
  productivity claims, and surveillance-style language.
- The website should feel like a precise native Mac utility while remaining
  visibly distinct from a generic Apple marketing clone.

## Evidence on Hand

- Public product documentation: `README.md`, `PRIVACY.md`, `SUPPORT.md`,
  `SECURITY.md`, and `CHANGELOG.md`.
- App icon: `assets/GifJot-Icon.png`.
- Public release: GifJot 0.1.2.
- Private native source provides verified interface language and tokens but is
  not published through this repository.
- There are no public testimonials, customer logos, usage benchmarks, or
  retention claims. Future work must not fabricate them.

## Product Principles

- Demonstrate the workflow before describing features.
- Make the download action obvious and low-friction.
- Treat privacy as product architecture, not decorative marketing.
- Preserve the small, focused scope that makes GifJot fast to understand.
- Measure the website and founding cohort without weakening the app's
  no-telemetry commitment.

## Accessibility & Inclusion

The public website must support keyboard navigation, visible focus, reduced
motion, sufficient contrast, semantic structure, and responsive layouts.
