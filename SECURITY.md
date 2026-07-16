# Security Policy

## Supported versions

GifJot has not published a stable release. Security fixes currently target the latest code on the default branch.

| Version | Supported |
| --- | --- |
| Default branch | Yes |
| Tagged public releases | None yet |

## Reporting a vulnerability

Do not disclose a suspected vulnerability in a public issue, discussion, pull request, screenshot, or recording.

Use GitHub's private vulnerability reporting flow:

<https://github.com/jamkoo/gifJot/security/advisories/new>

If private vulnerability reporting is unavailable, contact the repository owner through the contact method published on <https://github.com/jamkoo>. Do not include credentials, private recordings, or unrelated personal information.

Include only what is needed to understand the report:

- A concise description and potential impact.
- Affected commit, build, or source area.
- Reproduction steps using non-sensitive test content.
- Relevant macOS version and hardware architecture.
- Any known mitigation.

The maintainer will aim to acknowledge a report within seven days and provide a status update within fourteen days. Complex issues may require more time. Please allow a reasonable remediation and disclosure window before publishing details.

## Security-sensitive areas

Reports are especially useful when they involve:

- Capture occurring outside the selected region or after the user stops.
- Failure to exclude GifJot's own overlays from capture.
- Temporary frames or output persisting unexpectedly.
- Unsafe file paths, overwrites, symlink handling, or clipboard behavior.
- Unexpected network access, telemetry, or unnecessary permission requests.
- Dependency, build, signing, or distribution-chain compromise.

General bugs and feature requests should use the public issue forms instead.
