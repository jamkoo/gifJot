# GifJot macOS release test report

Use one report per release candidate. Replace every `unverified` result with
`pass`, `fail`, or `not applicable`, and add concise evidence. A release is not
ready while any required row is `unverified` or `fail`.

## Candidate

| Field | Value |
| --- | --- |
| Version and build | unverified |
| Commit SHA | unverified |
| DMG SHA-256 | unverified |
| Test date | unverified |
| Tester | unverified |
| Mac model | unverified |
| Processor | unverified |
| macOS version | unverified |
| Display arrangement and scale | unverified |
| Clean Mac without Xcode | unverified |

## Signing and installation

| Check | Result | Evidence |
| --- | --- | --- |
| `SHA256SUMS.txt` matches the downloaded DMG | unverified | |
| DMG contains a universal `arm64 x86_64` app | unverified | |
| App declares macOS 14.0 as its minimum | unverified | |
| `codesign --verify --deep --strict` accepts the app | unverified | |
| `stapler validate` accepts the DMG | unverified | |
| `spctl` accepts both the app and DMG | unverified | |
| DMG opens from a quarantined browser download | unverified | |
| Normal double-click launch works without Open Anyway | unverified | |
| Dragging the app to Applications works | unverified | |
| Launching once from the DMG works | unverified | |
| First and subsequent launches from Applications work | unverified | |
| A non-admin macOS user can launch and record | unverified | |

## Permission lifecycle

| Check | Result | Evidence |
| --- | --- | --- |
| Fresh install explains Screen Recording before capture | unverified | |
| Granting Screen Recording offers Quit and Reopen | unverified | |
| Relaunch returns to ready state and recording starts | unverified | |
| Denial followed by approval in Settings recovers | unverified | |
| Revoking permission produces a clear failure | unverified | |
| Accessibility permission is never requested | unverified | |

## Accessibility and appearance

| Check | Result | Evidence |
| --- | --- | --- |
| VoiceOver reaches the menu, selection, ready inspector, recording controls, result, and failure recovery in a logical order | unverified | |
| VoiceOver frame actions move and resize the selected region and announce updated dimensions | unverified | |
| Pointer-only frame hit areas are not announced as unusable buttons | unverified | |
| Keyboard-only flow can select, adjust, record, stop, retry, dismiss, and reveal output | unverified | |
| Focus returns predictably after permission, selection, completion, failure, and cancellation | unverified | |
| Largest configured macOS text size does not clip status text or controls | unverified | |
| Light and Dark appearances preserve hierarchy and AA text contrast | unverified | |
| Increase Contrast preserves boundaries, focus, and state distinctions | unverified | |
| Reduce Transparency keeps every surface and label legible | unverified | |
| Reduce Motion removes nonessential transitions without hiding state changes | unverified | |

## Displays and selection

| Check | Result | Evidence |
| --- | --- | --- |
| Internal Retina display records the selected pixels | unverified | |
| External 1x display records the correct region | unverified | |
| External 2x display records the correct region | unverified | |
| Displays to the left, right, and above primary work | unverified | |
| Negative global display origins work | unverified | |
| A selection cannot span displays | unverified | |
| Escape removes all selection overlays | unverified | |
| Armed frame move and resize remain on one display | unverified | |
| Full Screen, 16:9, 4:3, and 1:1 presets remain valid | unverified | |
| GifJot border, controller, HUD, and menu are absent from output | unverified | |

## Recording and output

| Check | Result | Evidence |
| --- | --- | --- |
| Menu action starts, confirms, stops, and cancels correctly | unverified | |
| Option-Command-G starts, confirms, stops, and cancels correctly | unverified | |
| Countdown through Complete states appear in order | unverified | |
| Cursor and countdown state are visible before recording begins | unverified | |
| Cursor on and off settings match output | unverified | |
| Original, 1280, 960, and 640 widths preserve aspect ratio | unverified | |
| Static intervals preserve duration without redundant visible frames | unverified | |
| GIF loops correctly in Finder and a browser | unverified | |
| GIF pastes into Finder, a browser, and a messaging or docs app | unverified | |
| Repeated recordings use collision-safe filenames | unverified | |
| Open, Copy, and Reveal retain the latest valid output | unverified | |
| Cancellation removes temporary and working files | unverified | |

## Failure and endurance

| Check | Result | Evidence |
| --- | --- | --- |
| Read-only or unavailable destination reports failure | unverified | |
| Low-disk or write failure never overwrites an existing GIF | unverified | |
| Clipboard failure preserves the saved GIF and reports the problem | unverified | |
| Recording failure stays visible until Retry, Dismiss, or Escape | unverified | |
| Repeated recordings leave no capture, overlay, or HUD behind | unverified | |
| A longer recording keeps memory bounded | unverified | |
| Dropped frames are reported instead of unbounded growth | unverified | |

## Upgrade and final decision

| Check | Result | Evidence |
| --- | --- | --- |
| Upgrade over the previous build preserves expected settings | unverified | |
| Existing Screen Recording permission behaves predictably | unverified | |
| Duplicate installation in another location behaves predictably | unverified | |
| Privacy policy and user-facing permission text match behavior | unverified | |
| Release notes list remaining limitations | unverified | |

**Decision:** unverified

**Blocking failures or accepted limitations:** unverified
