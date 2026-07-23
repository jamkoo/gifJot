# Product

<!-- impeccable:product-schema 1 -->

## Platform

adaptive

## Users

GifJot is primarily for product professionals and independent builders who need
to communicate visual software behavior quickly: product designers, product
managers, QA and support teams, marketers, engineers, and indie makers.

They create short interface demonstrations, bug reproductions, release updates,
and how-to moments for work surfaces such as Slack, Linear, GitHub, Notion,
documentation, and release notes. They value speed and confidence over capture
terminology or production controls.

## Product Purpose

GifJot turns a precisely selected screen region into a silent, looping,
paste-ready GIF. Success means a user can frame the moment, record it, and paste
the result into their work with almost no interruption.

## Positioning

GifJot is a screen recorder designed around the smallest useful communication
artifact: a short local GIF captured from a directly manipulated region and
immediately ready to paste. It does not require an account, upload content, or
route the user through a video library.

## Operating Context

GifJot lives in the macOS menu bar and is commonly invoked while another product
or work document is already open. The user selects one region on one display,
confirms its framing, records a short interaction, stops, and pastes or reveals
the resulting file.

The capture experience must coexist with visually dense applications and remain
legible without covering the content the user is trying to demonstrate.

## Capabilities and Constraints

- Native macOS 14-or-later application today; platform expansion comes only
  after the macOS workflow is stable.
- Captures one selected region on one display through ScreenCaptureKit.
- Produces silent GIFs only.
- Supports frame presets, direct moving and resizing, cursor inclusion,
  countdown, frame rate, output width, save, reveal, and clipboard copy.
- Local-only operation with no accounts, uploads, telemetry, ads, or watermark.
- No editor, timeline, audio, webcam, annotations, cloud sharing, or additional
  export formats in the current product boundary.
- Uses Screen Recording permission and does not require Accessibility
  permission for its global shortcut.

## Brand Commitments

- The product name is GifJot.
- Canva, Figma, and Loom set the expected craft level for approachability,
  direct manipulation, contextual controls, and recording confidence.
- Those products are interaction-quality references, not a request to copy
  their cloud, collaboration, video, or editing feature scope.
- Voice is concise, reassuring, and plainspoken. Product language should help
  users act without teaching them recorder jargon.

## Evidence on Hand

- A working native prototype and physical-Mac test workflow are documented in
  `README.md` and `TESTING.md`.
- The current capture flow, permission flow, menu-bar panel, frame geometry,
  and recording states are implemented under `apps/macos/GifJot`.
- A prior heuristic review is stored under `.impeccable/critique`.
- No testimonials, usage analytics, customer logos, benchmarks, or formal user
  research are available and must not be fabricated.

## Product Principles

1. Get out of the way of the work being captured.
2. Make the selected region feel directly manipulable and unquestionably ready.
3. Keep the default path to select, record, and paste immediate.
4. Reveal secondary choices in context instead of presenting setup.
5. Preserve local privacy and predictable file ownership.

## Accessibility & Inclusion

Use familiar macOS affordances, keyboard equivalents, strong visible state,
generous pointer targets, and meaningful VoiceOver labels. Critical information
must never depend on color, hover, or low-contrast microcopy alone.
