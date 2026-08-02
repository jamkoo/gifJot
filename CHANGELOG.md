# GifJot Changelog

## 0.1.10 — 2026-07-31

- Region selection now switches to a crosshair as soon as drag-to-select mode
  begins and restores the previous cursor when selection ends.
- Release-tag validation is now the authoritative hosted Mac gate; optional
  branch and Windows checks are available through manual dispatch.

## 0.1.9 — 2026-07-31

- Added draggable GIF and PNG previews to completion notifications and the
  latest-capture card.
- Reworked Settings into searchable Capture, GIF, Notifications, Shortcuts,
  Storage, and Privacy categories.
- Added a Save only screenshot option that leaves the clipboard unchanged.

## 0.1.8 — 2026-07-30

- Added persistent same-area capture for GIFs and PNGs, including the **R**
  selection shortcut.
- Made Jot, Again, and Show in Finder prominent after capture.
- Improved annotation color and placement previews.
- Isolated ordinary Debug builds from the production Screen Recording identity.

## 0.1.7 — 2026-07-29

- Added the fast selected-area PNG workflow and post-save Jot action.
- Unified recent GIF and PNG actions in the menu-bar panel.

## 0.1.6 — 2026-07-29

- Added signed Sparkle updates and update notifications.
- Added selected-area PNG screenshots and the shared Jot canvas.
- Added same-capture static annotation compositing for GIFs.
- Added toolbar pinning and left, bottom, and right docking.
- Made GIF Stop save and copy immediately, with optional Stop & Jot.

## 0.1.5 — 2026-07-27

- Added a Settings gear to the selected-frame toolbar so Settings remain
  accessible when macOS has no room for the GifJot menu-bar item.
- Added the standard `Command-,` Settings shortcut.
- Reopening a windowless running copy of GifJot now opens Settings.

## 0.1.4 — 2026-07-27

- Fixed the Screen Recording onboarding handoff after a normal quit and reopen.
- The next recording step now appears automatically without requiring the
  global shortcut.

## 0.1.3 — 2026-07-27

- Fixed Screen Recording recovery after replacing or updating GifJot.
- Made **Check Again** actively register and verify the installed build so
  permission changes no longer leave onboarding stuck.

## 0.1.2 — 2026-07-25

- Reworked the region-ready inspector with direct Pointer and Click Marker
  controls plus an explicit Move control for repositioning the capture area.
- Simplified inspector placement and improved movement guidance and
  accessibility.
- Kept the recording HUD active while transient popup and submenu windows are
  open.
- Fixed the About panel so it reports the installed app version.

## 0.1.1 — 2026-07-25

- Added optional click indicators that appear in completed recordings.
- Added a guided first-run experience for Screen Recording permission, the
  first recording, and the global shortcut.
- Added clearer hover and active feedback to the recording inspector's drag
  handle.
- Improved recording controls and capture startup feedback.

## 0.1.0 — 2026-07-24

Initial public macOS release.

- Native menu-bar region-to-GIF recording.
- Local-only processing with no accounts, uploads, telemetry, or advertising.
- Configurable output width, frame rate, countdown, cursor visibility, save
  location, and global shortcut.
- Apple silicon and Intel support on macOS 14 or later.
- Developer ID signing, Apple notarization, and stapled Gatekeeper ticket.
