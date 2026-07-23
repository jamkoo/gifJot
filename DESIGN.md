---
name: GifJot
description: A clear contextual capture tool for fast, paste-ready product GIFs.
colors:
  canvas-indigo: "#6758E8"
  canvas-indigo-pressed: "#5546D7"
  canvas-indigo-tint-light: "#EEECFF"
  canvas-indigo-tint-dark: "#322D5B"
  recording-red: "#D13D43"
  recording-red-pressed: "#B82F36"
  app-background-light: "#F9F9FB"
  app-background-dark: "#1F1F22"
  hud-surface-light: "#FCFCFD"
  hud-surface-dark: "#262629"
  hud-control-light: "#F2F2F5"
  hud-control-dark: "#353539"
  hud-hairline-light: "#D7D7DD"
  hud-hairline-dark: "#4A4A50"
  muted-ink-light: "#5D5D66"
  muted-ink-dark: "#AEAEB7"
  graphite: "#1D1D20"
  chalk: "#FAFAFC"
typography:
  headline:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "22px"
    fontWeight: 700
    letterSpacing: "-0.4px"
  title:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "14px"
    fontWeight: 600
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "13px"
    fontWeight: 400
  control:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "12px"
    fontWeight: 600
  measurement:
    fontFamily: "ui-monospace, 'SF Mono', monospace"
    fontSize: "12px"
    fontWeight: 600
  helper:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "11px"
    fontWeight: 500
rounded:
  keycap: "4px"
  control: "8px"
  surface: "12px"
  panel: "14px"
spacing:
  attached-gap: "6px"
  toolbar-inset: "7px"
  control-horizontal: "10px"
  screen-inset: "12px"
  content: "24px"
components:
  ready-inspector:
    backgroundColor: "{colors.hud-surface-light}"
    rounded: "{rounded.panel}"
    padding: "{spacing.toolbar-inset}"
    size: "310px 50px"
  frame-size-trigger:
    backgroundColor: "{colors.hud-control-light}"
    textColor: "{colors.graphite}"
    typography: "{typography.measurement}"
    rounded: "{rounded.control}"
    padding: "0 10px"
    height: "36px"
  button-record:
    backgroundColor: "{colors.canvas-indigo}"
    textColor: "{colors.chalk}"
    typography: "{typography.control}"
    rounded: "{rounded.control}"
    size: "86px 36px"
  button-stop:
    backgroundColor: "{colors.recording-red}"
    textColor: "{colors.chalk}"
    typography: "{typography.control}"
    rounded: "{rounded.control}"
    height: "36px"
---

# Design System: GifJot

## Overview

**Creative North Star: "The Contextual Canvas"**

GifJot should feel native to the creative work already happening on screen.
Framing is not a camera setup ritual; it is direct object manipulation. The
selected region is the canvas object, and controls appear as a calm contextual
inspector attached to it. The interface uses the familiarity, clarity, and
finish expected in Canva, Figma, and Loom without borrowing their cloud or
editorial complexity.

The world is adaptive, quiet, and confident. Neutral macOS materials carry the
chrome, one indigo accent communicates editability and readiness, and recording
red is reserved for an active capture. Guidance appears exactly where a
first-time user needs it, then recedes.

**Key Characteristics:**

- Direct manipulation instead of configuration-first flows.
- Adaptive light and dark materials that remain legible over any application.
- One compact contextual inspector with familiar macOS controls.
- Friendly, plainspoken guidance that disappears after it has taught the action.
- Clear semantic separation between ready, recording, processing, and complete.

## Colors

The palette is restrained: neutral system materials plus one creative-tool
indigo and one recording-only red.

### Primary

- **Canvas Indigo** (`#6758E8`): Selection outlines, focused controls, and the
  ready-to-record action. It means the region is editable and under GifJot's
  control.
- **Pressed Indigo** (`#5546D7`): Active and pressed state for Canvas Indigo.

### Secondary

- **Recording Red** (`#D13D43`): Live recording status, elapsed-time indicator,
  and Stop. It never decorates an idle or ready surface. Chalk text on this red
  has a 4.71:1 contrast ratio.

### Neutral

- **App Background Light / Dark** (`#F9F9FB` / `#1F1F22`): Permission,
  settings, and popover foundations.
- **HUD Surface Light / Dark** (`#FCFCFD` / `#262629`): The contextual
  inspector and recording-status surface.
- **HUD Control Light / Dark** (`#F2F2F5` / `#353539`): Dimension and More
  controls within the inspector.
- **HUD Hairline Light / Dark** (`#D7D7DD` / `#4A4A50`): Inspector and control
  outlines.
- **Muted Ink Light / Dark** (`#5D5D66` / `#AEAEB7`): Secondary labels and
  supporting copy.
- **Graphite** (`#1D1D20`): Strong light-appearance labels and measurements.
- **Chalk** (`#FAFAFC`): Text on indigo and recording red.

**The Semantic Accent Rule.** Indigo means editable or ready. Red means actively
recording or stopping. Neither color is decorative.

## Typography

GifJot uses the macOS system family throughout. Measurements use the system
monospaced design because pixel dimensions are data; all other copy uses the
standard system design.

### Hierarchy

- **Title** (semibold, 15–17 pt): First-use headings and permission state.
- **Body** (regular, 13 pt): Short explanations and recovery guidance.
- **Control** (semibold, 12–13 pt): Buttons and contextual actions.
- **Measurement** (semibold monospaced, 12 pt): Live width, height, and elapsed
  time.
- **Helper** (regular, 11–12 pt): One-line contextual coaching only.

**The Plain Language Rule.** Labels name the user's action or current result;
internal capture terminology never appears in the primary path.

## Layout

The selected region is the spatial anchor. Its inspector docks to the nearest
available horizontal edge and feels attached without covering the content. It
may move with the region and flip above or below it to remain on-screen.
The inspector sits exactly 6 pt from the frame, is 310 × 50 pt while ready, and
uses a 12 pt minimum screen inset. The active-status inspector is 306 × 60 pt.

The inspector is one compact group: measurement or preset first, optional
capture choices second, destructive dismissal quiet, and Record last. Secondary
settings use progressive disclosure rather than permanently expanding the bar.

First-use guidance sits adjacent to the selection and disappears after the user
successfully moves or resizes once. Permission and recovery surfaces use one
current-state message and one next action rather than a permanent multi-step
rail.

## Elevation & Depth

The inspector uses a native macOS material or adaptive solid surface with one
soft ambient shadow and a quiet hairline. The selection frame stays flat so its
geometry remains exact over detailed content. Popovers and menus use native
elevation.

**The Flat Canvas Rule.** Depth belongs to controls above the canvas, never to
the capture boundary itself.

## Shapes

Controls use gently rounded rectangles in the 8–12 pt range. The selection uses
four persistent corner grips with generous invisible hit areas; edge grips
appear only on hover, focus, or active resize. Grips are small light squares
with an indigo outline so they read as editor handles rather than annotation
points.

The frame outline is crisp and continuous. It does not use glow, dotted borders,
or eight permanently visible circular nodes.

## Components

### Selection Frame

- **Outline:** Canvas Indigo over a subtle white contrast stroke.
- **Handles:** Four persistent 7 pt corner squares. A hovered or active handle
  grows to 10 pt; each edge and corner has a 20 pt invisible hit target.
- **Movement:** Drag anywhere inside the frame. Arrow keys nudge 1 pt; Shift +
  arrow nudges 10 pt. Option + arrow makes the area narrower, wider, taller, or
  shorter.
- **Accessibility:** The frame exposes its exact GIF output dimensions and named
  VoiceOver actions for movement, width, and height.
- **Coaching:** `Drag inside to move  ·  Pull a corner to resize` appears once
  and is permanently dismissed after the first successful move or resize.

### Ready Inspector

- **Placement:** Attached 6 pt above the frame when possible, otherwise below;
  it stays within the 12 pt screen inset and moves with the selection.
- **Size and shape:** 310 × 50 pt, 14 pt continuous corners, 7 pt internal
  inset, adaptive HUD surface, hairline outline, and one native panel shadow.
- **Order:** Exact exported GIF dimensions and preset menu, More, then Record.
- **Keyboard:** Return starts recording. Escape cancels the selection.

### Frame Size Trigger

- **Display:** The entire `NNN × NNN px` measurement and chevron is clickable.
- **Meaning:** The measurement is the saved GIF size after the selected quality
  preset's maximum width is applied; it never reports a larger capture size
  that will be silently reduced.
- **Type:** 12 pt semibold monospaced with monospaced digits.
- **Presets:** Full Screen, 16:9, 4:3, and 1:1.

### More Menu

- **Trigger:** A 36 × 36 pt ellipsis control with an 8 pt radius.
- **Contents:** Show cursor, countdown (Off, 1 second, or 3 seconds), then
  Cancel selection after a separator.
- **Rule:** Only secondary capture choices belong here; the first view remains
  frame-first.

### Recording Status

- **Surface:** 306 × 60 pt adaptive inspector with a 9 pt recording-red dot,
  state label, and monospaced elapsed time.
- **Stop:** Recording Red with Chalk text. Red appears only while recording is
  live or on the explicit stop action.

### Permission Surface

- **Structure:** A 500 pt-wide adaptive panel with 24 pt content inset, one
  current-state headline, one short explanation, one privacy note, and the
  next action.
- **Recovery:** Denied access offers Check Again and Open System Settings.
  Authorized access offers Record an Area; a restart is requested only when
  macOS has just granted access to the running process.

### Initial Area Selection

- **Surface:** A quiet 42% outside scrim, native light instruction badge, Canvas
  Indigo boundary, four small square grips, and the exact saved GIF size.
- **Language:** `Drag to select an area  ·  Esc to cancel`.
- **Keyboard:** Any arrow key creates a centered area and moves it; Option +
  arrow resizes, Return confirms, and Escape cancels.

## Do's and Don'ts

### Do:

- **Do** make the selected region feel like a familiar editable object.
- **Do** keep live dimensions readable and directly actionable.
- **Do** use native menus, keyboard actions, materials, and accessibility
  semantics wherever they fit.
- **Do** let one-time guidance recede after the corresponding action is learned.
- **Do** keep Record unmistakable without making it visually alarming.

### Don't:

- **Don't** style the primary path like camera hardware or a developer overlay.
- **Don't** use red before recording is live.
- **Don't** expose quality, frame rate, output width, and countdown as equal
  first-step decisions.
- **Don't** leave movement, resizing, or cursor state dependent on hover alone.
- **Don't** add cloud, timeline, audio, or editor patterns to imitate the
  reference products.
