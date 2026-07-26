# GifJot activation metrics

## North-star metric

**Weekly activated users:** people who create their first GIF during a rolling
seven-day window.

GifJot currently keeps first-GIF completion on the Mac. It is not transmitted
because the product promises that the app has no telemetry. Do not report
website clicks or downloads as activated users.

**Decision:** preserve the no-telemetry product boundary. Measure activation
through asynchronous confirmations from the first 25 recruited test users using
the [first-25 activation playbook](FIRST-25.md).

## Current measurable funnel

| Stage | Event or source | Meaning |
| --- | --- | --- |
| Visit | Vercel Web Analytics page view | Someone loaded gifjot.com. |
| Qualified visit | `product_proof_viewed` | Someone reached the animated use-case proof. |
| Download intent | `download_click` | Someone selected a download CTA. Break down by `location` and `version`. |
| Download request | GitHub release asset `downloadCount` | GitHub served the release DMG. |
| Activation | Local `firstRun.hasCompletedFirstGIF` | The app created its first GIF on that Mac. Not transmitted. |

## Weekly scorecard

Review the previous seven days every Monday:

1. Visitors
2. `product_proof_viewed`
3. `download_click`
4. GitHub `GifJot.dmg` download count
5. First-GIF confirmations from recruited test users
6. Users who made another GIF or replied that they still use GifJot

Calculate:

- **Proof rate:** qualified visits / visitors
- **Download intent rate:** download clicks / visitors
- **Release request rate:** new DMG download requests / visitors
- **Observed activation rate:** confirmed first GIFs / cohort entrants

The first target cohort is 25 people who agree to try GifJot independently, 15
installs, 10 confirmed first GIFs, and 5 people still using GifJot seven days
later.

## Privacy boundary

Do not add a native network event without changing the website, app privacy
statement, and onboarding disclosure together. The least disruptive future
option is an explicit, default-off consent for two anonymous milestones:
`app_opened` and `first_gif_created`. Neither event should contain an install
identifier, filename, screen content, recording dimensions, duration, or other
recording metadata.
