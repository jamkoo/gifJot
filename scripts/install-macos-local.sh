#!/bin/zsh

set -euo pipefail

readonly script_dir="${0:A:h}"
readonly repository_root="${script_dir:h}"
readonly project_path="${repository_root}/apps/macos/GifJot.xcodeproj"
readonly scheme_name="GifJot"
readonly bundle_identifier="com.gifjot.GifJot"
readonly signing_identity="${GIFJOT_SIGNING_IDENTITY:-GifJot Local Development}"
readonly login_keychain="$(
  security default-keychain -d user | tr -d ' "'
)"
readonly derived_data_path="${GIFJOT_DERIVED_DATA_PATH:-/tmp/gifjot-local-derived-data}"
readonly built_app="${derived_data_path}/Build/Products/Debug/GifJot.app"
readonly installed_app="/Applications/GifJot.app"
readonly staging_app="/Applications/.GifJot.installing.$$.app"
readonly backup_app="/tmp/GifJot.previous.$(date +%Y%m%d-%H%M%S).app"
readonly installed_executable="${installed_app}/Contents/MacOS/GifJot"

installed_app_pids() {
  ps -axo pid=,comm= \
    | awk -v executable="${installed_executable}" '$2 == executable { print $1 }'
}

wait_for_installed_app_to_exit() {
  local remaining_pids
  local attempt

  for attempt in {1..25}; do
    remaining_pids="$(installed_app_pids)"
    if [[ -z "${remaining_pids}" ]]; then
      return 0
    fi
    sleep 0.2
  done

  return 1
}

if ! security find-identity -v -p codesigning "${login_keychain}" \
  | grep -Fq "\"${signing_identity}\""; then
  print -u2 "Missing valid code-signing identity: ${signing_identity}"
  print -u2 "Install the GifJot local-development identity in the login keychain first."
  exit 1
fi

certificate_sha1="$(
  security find-certificate \
    -c "${signing_identity}" \
    -Z \
    "${login_keychain}" \
    | awk '/SHA-1 hash:/{print $3; exit}'
)"
certificate_sha1="${certificate_sha1:l}"

if [[ ! "${certificate_sha1}" =~ '^[[:xdigit:]]{40}$' ]]; then
  print -u2 "Could not resolve the SHA-1 fingerprint for ${signing_identity}."
  exit 1
fi

readonly designated_requirement="designated => identifier \"${bundle_identifier}\" and certificate leaf = H\"${certificate_sha1}\""

print "Building GifJot…"
xcodebuild \
  -project "${project_path}" \
  -scheme "${scheme_name}" \
  -configuration Debug \
  -destination 'platform=macOS' \
  -derivedDataPath "${derived_data_path}" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  build

if [[ ! -d "${built_app}" ]]; then
  print -u2 "Build completed without producing ${built_app}."
  exit 1
fi

print "Signing with ${signing_identity}…"
codesign \
  --force \
  --sign "${signing_identity}" \
  --identifier "${bundle_identifier}" \
  --requirements "=${designated_requirement}" \
  --timestamp=none \
  "${built_app}"

codesign --verify --strict --verbose=2 "${built_app}"

actual_requirement="$(
  codesign -d -r- "${built_app}" 2>&1 \
    | awk '/^designated =>/{print; exit}'
)"
if [[ "${actual_requirement}" != "${designated_requirement}" ]]; then
  print -u2 "The signed app has an unexpected designated requirement:"
  print -u2 "${actual_requirement}"
  exit 1
fi

if [[ -e "${staging_app}" ]]; then
  find "${staging_app}" -depth -delete
fi

ditto "${built_app}" "${staging_app}"
codesign --verify --strict --verbose=2 "${staging_app}"

running_pids="$(installed_app_pids)"
if [[ -n "${running_pids}" ]]; then
  print "Stopping the installed GifJot process…"
  osascript -e 'tell application id "com.gifjot.GifJot" to quit' >/dev/null 2>&1 || true

  if ! wait_for_installed_app_to_exit; then
    running_pids="$(installed_app_pids)"
    for running_pid in ${(f)running_pids}; do
      kill "${running_pid}" >/dev/null 2>&1 || true
    done
  fi

  if ! wait_for_installed_app_to_exit; then
    print -u2 "GifJot is still running; the installed app was not replaced."
    find "${staging_app}" -depth -delete
    exit 1
  fi
fi

if [[ -e "${installed_app}" ]]; then
  mv "${installed_app}" "${backup_app}"
fi

if ! mv "${staging_app}" "${installed_app}"; then
  if [[ -e "${backup_app}" && ! -e "${installed_app}" ]]; then
    mv "${backup_app}" "${installed_app}"
  fi
  exit 1
fi

open "${installed_app}"

print "Installed and launched ${installed_app}"
if [[ -e "${backup_app}" ]]; then
  print "Previous build preserved at ${backup_app}"
fi
print "${designated_requirement}"
