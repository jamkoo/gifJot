# macOS release signing and notarization

GifJot is distributed directly rather than through the Mac App Store. A public
test build therefore needs a Developer ID Application signature, Apple's
notarization approval, a stapled ticket, and a clean-Mac test before it is
published.

Never commit certificates, private keys, app-specific passwords, API keys,
notary credentials, or local signing configuration.

## 1. Confirm the permanent identity

Before the first public build, confirm that `com.gifjot.GifJot` is the permanent
bundle identifier. Changing it later makes macOS treat the app as a different
application and can disrupt Screen Recording permission continuity.

The release script deliberately requires an explicit confirmation:

```sh
export GIFJOT_CONFIRM_BUNDLE_ID=com.gifjot.GifJot
```

## 2. Install a Developer ID Application certificate

An active Apple Developer Program membership is required. The Account Holder
creates a **Developer ID Application** certificate in Certificates,
Identifiers & Profiles and installs the downloaded certificate in the login
Keychain. A `.dmg` uses the Application certificate; a Developer ID Installer
certificate is only needed for a `.pkg`.

Verify that the certificate and its private key are available:

```sh
security find-identity -v -p codesigning
```

The output must contain an identity shaped like:

```text
Developer ID Application: Team Name (ABCDEFGHIJ)
```

Set the 10-character Team ID. If the Keychain contains more than one Developer
ID Application identity, also select the exact identity:

```sh
export GIFJOT_TEAM_ID=ABCDEFGHIJ
export GIFJOT_SIGNING_IDENTITY='Developer ID Application: Team Name (ABCDEFGHIJ)'
```

## 3. Store notarization credentials in the Keychain

Create an app-specific password for the Apple Account used by the developer
team. Store it through `notarytool`'s secure prompt so it is not placed in shell
history:

```sh
xcrun notarytool store-credentials gifjot-notary \
  --apple-id 'developer@example.com' \
  --team-id "${GIFJOT_TEAM_ID}"
```

Enter the app-specific password when prompted. Then select the profile:

```sh
export GIFJOT_NOTARY_PROFILE=gifjot-notary
```

The profile name and Team ID are not secrets. The password remains in the
login Keychain.

## 4. Run preflight and create the release

From the repository root:

```sh
./scripts/release-macos.sh --preflight
./scripts/release-macos.sh
```

The release command refuses a dirty Git working tree, runs the shared and
complete macOS tests, builds a universal Release app, signs the app and DMG
with a secure timestamp and hardened runtime, submits the final DMG to Apple,
records Apple's log, staples the ticket, and requires both `codesign` and
`spctl` verification to pass.

Successful artifacts are written beneath `build/release-macos/`. Only publish
the DMG after completing the physical test report.

## 5. Complete clean-Mac testing

Copy `RELEASE_TEST_REPORT_TEMPLATE.md` for the exact commit being tested. Test
the downloaded artifact, not an app copied directly from the development
machine. At least one test Mac should not have Xcode or a prior GifJot install.

Keep the report with the release records and mark untested rows as
`unverified`; never infer a pass from automated tests.

## 6. Publish

Confirm that the version, build number, commit, architectures, Team ID, bundle
ID, notarization status, and checksums in `BUILD-INFO.txt` and
`SHA256SUMS.txt` match the tested DMG. Publish those files together and retain
the notarization response, Apple notarization log, and completed manual report.
