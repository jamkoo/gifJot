---
name: GifJot
description: Turn any part of your Mac screen into a paste-ready GIF.
colors:
  canvas-indigo: "#6758E8"
  pressed-indigo: "#5546D7"
  indigo-tint: "#EEECFF"
  optical-body: "#F9F9FB"
  vellum: "#F1F1F4"
  shell-highlight: "#FFFFFF"
  optical-hairline: "#DADAE0"
  muted-ink: "#5D5D66"
  graphite: "#1D1D20"
  success: "#2E7D4C"
  warning: "#B96D0F"
  camera-black: "#000000"
  success-tint: "#EAF6EE"
  indigo-edge: "#D5D0FF"
  traffic-red: "#FF5F57"
  traffic-yellow: "#FEBC2E"
  traffic-green: "#28C840"
typography:
  display:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif"
    fontSize: "clamp(3.25rem, 8vw, 6rem)"
    fontWeight: 720
    lineHeight: 0.94
    letterSpacing: "-0.04em"
  body:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "1.0625rem"
    fontWeight: 450
    lineHeight: 1.58
  label:
    fontFamily: "-apple-system, BlinkMacSystemFont, 'SF Pro Text', sans-serif"
    fontSize: "0.8125rem"
    fontWeight: 650
    lineHeight: 1.2
  mono:
    fontFamily: "ui-monospace, 'SFMono-Regular', Menlo, monospace"
    fontSize: "0.75rem"
    fontWeight: 550
    lineHeight: 1.2
rounded:
  detail: "2px 3px 4px 5px 6px 7px 8px 9px"
  control: "10px"
  surface: "11px 12px 13px 14px 15px"
  panel: "20px 22px 23px"
  pill: "999px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "16px"
  lg: "24px"
  xl: "40px"
  section: "112px"
components:
  button-primary:
    backgroundColor: "{colors.canvas-indigo}"
    textColor: "{colors.shell-highlight}"
    rounded: "{rounded.control}"
    padding: "14px 20px"
  button-primary-hover:
    backgroundColor: "{colors.pressed-indigo}"
    textColor: "{colors.shell-highlight}"
    rounded: "{rounded.control}"
    padding: "14px 20px"
  button-secondary:
    backgroundColor: "{colors.shell-highlight}"
    textColor: "{colors.graphite}"
    rounded: "{rounded.control}"
    padding: "14px 20px"
---

# Design System: GifJot

## Overview

**Creative North Star: "The Capture Canvas"**

GifJot's visual world comes from the moment a user drags a precise selection
around something worth showing. The website expands the native app's bright
optical surfaces, camera-black ink, and Canvas Indigo signal into a decisive
capture field. It should feel machined and calm rather than ornamental.

The site inherits the native app's concise geometry and direct language, but it
does not imitate a standard Apple product page. The capture frame itself is the
composition, proof, and recurring interaction.

**Key Characteristics:**

- Bright, high-clarity optical surfaces.
- One indigo action signal with camera-black structure.
- Capture corners, selection handles, and keycaps used as functional notation.
- Large demonstrations paired with compact operational copy.
- Motion follows the capture sequence: select, record, finish, paste.

## Colors

The palette is an optical neutral field controlled by one rare, unmistakable
indigo signal.

### Primary

- **Canvas Indigo** (`#6758E8`): capture boundaries, primary actions, active
  controls, and the shortest route through the page.
- **Pressed Indigo** (`#5546D7`): pressed and high-intensity action states.
- **Indigo Tint** (`#EEECFF`): selected regions and privacy-supporting context.

### Neutral

- **Optical Body** (`#F9F9FB`): primary page background.
- **Vellum** (`#F1F1F4`): secondary work surfaces and quiet bands.
- **Shell Highlight** (`#FFFFFF`): controls and raised optical surfaces.
- **Optical Hairline** (`#DADAE0`): structural separators and control outlines.
- **Muted Ink** (`#5D5D66`): secondary explanatory copy.
- **Graphite** (`#1D1D20`): primary text and camera-like framing.

### Named Rules

**The Live Signal Rule.** Canvas Indigo marks an action, a selected capture
region, or a real state. It is never scattered as decoration.

## Typography

**Display Font:** the native Apple display stack.
**Body Font:** the native Apple text stack.

**Character:** compact, optical, and native to the product's working
environment. Display text is forceful through scale and rhythm rather than
through a separate decorative face.

### Hierarchy

- **Display** (720, `clamp(3.25rem, 8vw, 6rem)`, 0.94): the first-viewport
  promise only.
- **Headline** (700, `clamp(2.25rem, 5vw, 4rem)`, 1): section-level decisions.
- **Title** (650, `1.25rem`, 1.2): compact workflow labels.
- **Body** (450, `1.0625rem`, 1.58): explanatory copy, capped near 68 characters.
- **Label** (650, `0.8125rem`, 1.2): controls, statuses, and verified facts.
- **Micro UI** (550–700, `0.55rem`–`1rem`, 1–1.3): the illustrative
  capture instrument only. These sizes recreate compact native controls and
  are not used for page reading text.
- **Mono** (550, `0.75rem`, 1.2): local paths, shortcuts, timers, and keycaps.
- **Fluid display ranges:** hero and closing headlines may use optical
  `clamp()` endpoints tuned per breakpoint as long as they preserve the
  display hierarchy and remain within `2.35rem`–`5.65rem`.

### Named Rules

**The One-Breath Rule.** The primary promise must be understood in one breath;
supporting copy carries mechanism and constraints.

## Layout

The page is a capture field rather than a stack of equal marketing cards. A
maximum-width canvas of 1240px uses a twelve-column grid, with demonstrations
allowed to break the text measure and occupy the dominant area. Sections change
density: immersive capture field, compact proof band, three-step workflow, then
a focused close.

On smaller screens the capture demonstration remains first-class, reflowing
above the copy and preserving a minimum 44px control target. Section spacing
compresses from 112px to 72px.

## Elevation & Depth

Depth is structural and optical. Raised white controls use a small downward
offset plus a soft ambient blur. Large surfaces rely on tonal separation rather
than ornamental shadows.

### Shadow Vocabulary

- **Control Lift** (`0 2px 3px rgba(29,29,32,.08), 0 12px 28px rgba(29,29,32,.10)`):
  primary actions and the active recorder control.
- **Panel Depth** (`0 18px 50px rgba(29,29,32,.14)`): the single main capture
  demonstration.

### Named Rules

**The One Instrument Rule.** Only the primary demonstration receives panel
depth. Secondary content stays on the canvas.

## Shapes

Controls use 10px corners, surfaces use 11–15px corners, and dominant capture
panels use 20–23px corners. The illustrative native UI uses a 2–9px detail
scale where its geometry requires tighter radii. Capture boundaries themselves
use square optical corners and small circular handles. A 999px pill is reserved
for compact status text, never for primary buttons or containers.

## Components

### Buttons

- **Shape:** compact continuous corners (`10px`) with 44px minimum height.
- **Primary:** Canvas Indigo with white text.
- **Hover / Focus:** Pressed Indigo on hover; a two-layer indigo focus ring
  outside the control.
- **Secondary:** white or transparent with Graphite text and an optical
  hairline.

### Cards / Containers

- **Corner Style:** 14px for compact surfaces; 20px for the capture instrument.
- **Background:** Shell Highlight on Optical Body or Vellum.
- **Shadow Strategy:** tonal by default; panel depth only on the main demo.
- **Border:** optical hairline when a control boundary needs definition.
- **Use-case previews:** secondary examples are composed, scenario-specific
  product scenes with real labels and interaction states. Never use gray bars
  or generic rectangles as stand-ins for missing screenshots.

### Navigation

The navigation is quiet and horizontal on desktop, with the icon and product
name anchoring the left edge and Download anchoring the right. On mobile, only
the identity and primary download action remain.

### Capture Instrument

The signature component mirrors the native macOS capture UI rather than using a
marketing approximation:

- **Adjustable frame:** a 1px Canvas Indigo boundary with a 2px white contrast
  edge, four 12px circular corner handles, four 24×6px edge rails, and a
  centered 36×28px move grip.
- **Recording frame:** the boundary thickens to 3px, the handles and move grip
  disappear, and Canvas Indigo washes the area outside the capture at 16%.
- **Control HUD:** a 440×50px Shell Highlight panel with a 14px corner radius,
  Optical Hairline border, 7px inset, and 36px controls.
- **State language:** ready shows dimensions, pointer/click/countdown/pin
  options, and Record; recording shows a 9px live signal, timer, and Stop;
  completion says “Copied. Press ⌘V to paste” with a Reveal action.

The web demo may responsively omit secondary pointer options when space is
constrained, but it must preserve the native frame geometry, control hierarchy,
state language, and three-step mechanism without inventing product capabilities.

## Motion

Motion behaves like a capture operation: acquire, lock, record, and release.
GSAP owns authored sequencing and ScrollTrigger owns one-shot viewport cues;
routine hover and focus feedback remains CSS-native.

- **Focal entrance:** the hero copy resolves first, then the capture instrument
  opens through a bounded clip and its selection frame locks into place.
- **Continuity:** the workflow rail draws once while its three steps resolve in
  sequence, making the product loop legible without scroll hijacking.
- **Product feedback:** capture HUD contents acknowledge each Select, Record,
  and Paste state change; example cursors traverse their miniature output scenes.
- **Privacy relationship:** the local capture boundary resolves before the
  blocked cloud moves away from it.
- **Budget:** all sequences are one-shot and use transform, opacity, or bounded
  clip-path work. There is no pinned scrolling, smoothing layer, or persistent
  decorative loop.
- **Accessibility:** `prefers-reduced-motion: reduce` bypasses GSAP sequences
  and the capture demo’s automatic state cycling.

## Do's and Don'ts

### Do:

- **Do** let the product mechanism dominate the first viewport.
- **Do** use real GifJot language and verified platform constraints.
- **Do** preserve bright neutral space around indigo state changes.
- **Do** make keyboard focus and reduced-motion behavior explicit.

### Don't:

- **Don't** use gradient text, neon halos, glass decoration, or generic tech
  grids.
- **Don't** turn privacy into a fear campaign.
- **Don't** fabricate testimonials, user counts, time savings, or benchmarks.
- **Don't** organize the page as a uniform grid of feature cards.
