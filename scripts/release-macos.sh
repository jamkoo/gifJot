#!/bin/zsh

set -euo pipefail

readonly script_dir="${0:A:h}"
readonly repository_root="${script_dir:h}"
readonly project_path="${repository_root}/apps/macos/GifJot.xcodeproj"
readonly scheme_name="GifJot"
readonly expected_bundle_identifier="${GIFJOT_CONFIRM_BUNDLE_ID:-}"
readonly expected_team_identifier="${GIFJOT_TEAM_ID:-}"
readonly notary_profile="${GIFJOT_NOTARY_PROFILE:-}"
readonly derived_data_path="${GIFJOT_DERIVED_DATA_PATH:-${repository_root}/build/release-macos-derived-data}"
readonly distribution_path="${GIFJOT_DIST_DIR:-${repository_root}/build/release-macos}"
readonly staging_path="${distribution_path}/dmg-root"
readonly built_app="${derived_data_path}/Build/Products/Release/GifJot.app"
readonly release_zip="${distribution_path}/GifJot.app.zip"
readonly release_dmg="${distribution_path}/GifJot.dmg"
readonly notarization_response="${distribution_path}/notarization-response.plist"
readonly notarization_log="${distribution_path}/notarization-log.json"
readonly login_keychain="$(
  security default-keychain -d user | tr -d ' "'
)"
readonly preflight_only="${1:-}"

fail() {
  print -u2 "release-macos: $*"
  exit 1
}

require_command() {
  command -v "$1" >/dev/null 2>&1 || fail "Missing required command: $1"
}

remove_tree_contents() {
  local target="$1"

  [[ -n "${target}" ]] || fail "Refusing to clean an empty path."
  [[ "${target}" != "/" ]] || fail "Refusing to clean /."
  [[ "${target}" == "${repository_root}/build/"* ]] \
    || fail "Refusing to clean a path outside ${repository_root}/build: ${target}"

  if [[ -e "${target}" ]]; then
    find "${target}" -depth -delete
  fi
}

resolve_signing_identity() {
  local requested_identity="${GIFJOT_SIGNING_IDENTITY:-}"
  local identities
  local identity_count

  identities="$(
    security find-identity -v -p codesigning "${login_keychain}" \
      | sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p'
  )"

  if [[ -n "${requested_identity}" ]]; then
    print -r -- "${identities}" | grep -Fxq "${requested_identity}" \
      || fail "Developer ID identity not found in the login keychain: ${requested_identity}"
    print -r -- "${requested_identity}"
    return
  fi

  identity_count="$(
    print -r -- "${identities}" \
      | awk 'NF { count += 1 } END { print count + 0 }'
  )"

  case "${identity_count}" in
    0)
      fail "No valid Developer ID Application identity exists in the login keychain."
      ;;
    1)
      print -r -- "${identities}"
      ;;
    *)
      print -u2 "More than one Developer ID Application identity is available:"
      print -u2 -r -- "${identities}"
      fail "Set GIFJOT_SIGNING_IDENTITY to the exact identity to use."
      ;;
  esac
}

verify_notarization_status() {
  local status
  local submission_identifier

  [[ -f "${notarization_response}" ]] \
    || fail "Notary service did not produce a response file."

  status="$(
    plutil -extract status raw -o - "${notarization_response}" 2>/dev/null \
      || true
  )"
  submission_identifier="$(
    plutil -extract id raw -o - "${notarization_response}" 2>/dev/null \
      || true
  )"

  if [[ -n "${submission_identifier}" ]]; then
    xcrun notarytool log \
      "${submission_identifier}" \
      --keychain-profile "${notary_profile}" \
      "${notarization_log}"
  fi

  [[ "${status}" == "Accepted" ]] \
    || fail "Notarization status was '${status:-unknown}'. Review ${notarization_log}."
}

for required_command in \
  codesign \
  ditto \
  git \
  hdiutil \
  lipo \
  plutil \
  security \
  shasum \
  spctl \
  swift \
  xcodebuild \
  xcrun
do
  require_command "${required_command}"
done

[[ "$#" -le 1 ]] \
  || fail "Usage: ./scripts/release-macos.sh [--preflight]"
[[ -z "${preflight_only}" || "${preflight_only}" == "--preflight" ]] \
  || fail "Usage: ./scripts/release-macos.sh [--preflight]"

[[ "${expected_bundle_identifier}" == "com.gifjot.GifJot" ]] \
  || fail "Confirm the release bundle ID by setting GIFJOT_CONFIRM_BUNDLE_ID=com.gifjot.GifJot."
[[ "${expected_team_identifier}" =~ '^[[:alnum:]]{10}$' ]] \
  || fail "Set GIFJOT_TEAM_ID to the 10-character Apple Developer Team ID."
[[ -n "${notary_profile}" ]] \
  || fail "Set GIFJOT_NOTARY_PROFILE to a notarytool Keychain profile name."

signing_identity="$(resolve_signing_identity)" || exit 1
readonly signing_identity
[[ "${signing_identity}" == *"(${expected_team_identifier})" ]] \
  || fail "The signing identity does not belong to Team ID ${expected_team_identifier}: ${signing_identity}"

print "Validating notary credentials in Keychain profile '${notary_profile}'…"
xcrun notarytool history \
  --keychain-profile "${notary_profile}" \
  --output-format plist \
  >/dev/null

if [[ "${preflight_only}" == "--preflight" ]]; then
  print "Release preflight passed."
  print "Signing identity: ${signing_identity}"
  print "Team ID: ${expected_team_identifier}"
  print "Bundle ID: ${expected_bundle_identifier}"
  exit 0
fi

[[ -z "$(git -C "${repository_root}" status --porcelain)" ]] \
  || fail "The Git working tree must be clean before creating a release."

remove_tree_contents "${distribution_path}"
mkdir -p "${distribution_path}" "${staging_path}"

print "Running shared Swift tests…"
swift test --package-path "${repository_root}"

print "Running the complete macOS test target…"
xcodebuild \
  -project "${project_path}" \
  -scheme "${scheme_name}" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "${derived_data_path}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  test

print "Building a universal Release app…"
xcodebuild \
  -project "${project_path}" \
  -scheme "${scheme_name}" \
  -configuration Release \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "${derived_data_path}" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  clean build

[[ -d "${built_app}" ]] \
  || fail "Release build did not produce ${built_app}."

actual_bundle_identifier="$(
  plutil -extract CFBundleIdentifier raw "${built_app}/Contents/Info.plist"
)"
[[ "${actual_bundle_identifier}" == "${expected_bundle_identifier}" ]] \
  || fail "Built bundle ID is ${actual_bundle_identifier}; expected ${expected_bundle_identifier}."

architectures="$(lipo -archs "${built_app}/Contents/MacOS/GifJot")"
for architecture in arm64 x86_64; do
  [[ " ${architectures} " == *" ${architecture} "* ]] \
    || fail "Release executable is missing ${architecture}."
done

minimum_macos="$(
  plutil -extract LSMinimumSystemVersion raw "${built_app}/Contents/Info.plist"
)"
[[ "${minimum_macos}" == "14.0" ]] \
  || fail "Release app declares macOS ${minimum_macos}; expected 14.0."

print "Signing the app with ${signing_identity}…"
codesign \
  --force \
  --options runtime \
  --sign "${signing_identity}" \
  --timestamp \
  "${built_app}"

codesign --verify --deep --strict --verbose=2 "${built_app}"

signature_details="$(codesign -dv --verbose=4 "${built_app}" 2>&1)"
print -r -- "${signature_details}" \
  | grep -Eq '^Authority=Developer ID Application:' \
  || fail "The app is not signed by a Developer ID Application certificate."
print -r -- "${signature_details}" \
  | grep -Eq '^CodeDirectory .*flags=.*runtime' \
  || fail "The app signature does not enable the hardened runtime."
print -r -- "${signature_details}" \
  | grep -Eq '^Timestamp=' \
  || fail "The app signature does not contain a secure timestamp."

actual_team_identifier="$(
  print -r -- "${signature_details}" \
    | awk -F= '/^TeamIdentifier=/{print $2; exit}'
)"
[[ "${actual_team_identifier}" == "${expected_team_identifier}" ]] \
  || fail "Signed app Team ID is ${actual_team_identifier:-missing}; expected ${expected_team_identifier}."

if codesign -d --entitlements :- "${built_app}" 2>/dev/null \
  | grep -Fq "com.apple.security.get-task-allow"; then
  fail "Release app contains the forbidden get-task-allow entitlement."
fi

print "Creating and signing the distribution disk image…"
ditto "${built_app}" "${staging_path}/GifJot.app"
ln -s /Applications "${staging_path}/Applications"

hdiutil create \
  -volname "GifJot" \
  -srcfolder "${staging_path}" \
  -ov \
  -format UDZO \
  "${release_dmg}"

codesign \
  --force \
  --identifier "${expected_bundle_identifier}.dmg" \
  --sign "${signing_identity}" \
  --timestamp \
  "${release_dmg}"

codesign --verify --strict --verbose=2 "${release_dmg}"
hdiutil verify "${release_dmg}"

print "Submitting the signed DMG to Apple's notary service…"
if ! xcrun notarytool submit \
    "${release_dmg}" \
    --keychain-profile "${notary_profile}" \
    --wait \
    --timeout 2h \
    --output-format plist \
    >"${notarization_response}"
then
  print -u2 "The notary submission command reported an error."
fi

verify_notarization_status

print "Stapling and validating the notarization tickets…"
xcrun stapler staple -v "${release_dmg}"
xcrun stapler validate -v "${release_dmg}"
xcrun stapler staple -v "${built_app}"
xcrun stapler validate -v "${built_app}"

print "Verifying Gatekeeper acceptance…"
spctl --assess --type execute --verbose=4 "${built_app}"
spctl \
  --assess \
  --type open \
  --context context:primary-signature \
  --verbose=4 \
  "${release_dmg}"

ditto \
  -c \
  -k \
  --sequesterRsrc \
  --keepParent \
  "${built_app}" \
  "${release_zip}"

version="$(
  plutil -extract CFBundleShortVersionString raw "${built_app}/Contents/Info.plist"
)"
build_number="$(
  plutil -extract CFBundleVersion raw "${built_app}/Contents/Info.plist"
)"
commit_sha="$(git -C "${repository_root}" rev-parse HEAD)"

{
  print "GifJot macOS release"
  print "Version: ${version} (${build_number})"
  print "Commit: ${commit_sha}"
  print "Architectures: ${architectures}"
  print "Minimum macOS: ${minimum_macos}"
  print "Bundle ID: ${actual_bundle_identifier}"
  print "Team ID: ${actual_team_identifier}"
  print "Signing: Developer ID Application"
  print "Notarization: Accepted and stapled"
} >"${distribution_path}/BUILD-INFO.txt"

(
  cd "${distribution_path}"
  shasum -a 256 \
    GifJot.dmg \
    GifJot.app.zip \
    >SHA256SUMS.txt
)

remove_tree_contents "${staging_path}"

print
print "Release artifacts are ready in ${distribution_path}:"
print "  ${release_dmg}"
print "  ${release_zip}"
print "  ${distribution_path}/SHA256SUMS.txt"
print "  ${distribution_path}/BUILD-INFO.txt"
print "  ${notarization_response}"
print "  ${notarization_log}"
