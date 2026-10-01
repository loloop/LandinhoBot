#!/bin/bash
set -euo pipefail

# Run only while holding the parent's exclusive build/simulator lease.
# This script uses an already booted, explicitly assigned simulator; it never boots one.
simulator_id="${1:?Usage: capture.sh ASSIGNED_BOOTED_UDID DERIVED_DATA_PATH}"
derived_dir="${2:?Pass the parent-approved app DerivedData path}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/quick-actions"
entry="$repo_dir/app/VroomVroom/VroomVroomApp.swift"
bundle_id="me.mauriciocardozo.racing.vroomvroom"
fixture_pid=""

xcrun simctl list devices available -j | python3 -c '
import json, sys
device_id = sys.argv[1]
devices = [d for group in json.load(sys.stdin)["devices"].values() for d in group]
assert any(d["udid"] == device_id and d["state"] == "Booted" for d in devices), "Assigned simulator is not booted"
' "$simulator_id"
git -C "$repo_dir" diff --quiet -- "$entry"
backup_file="$(mktemp /tmp/landinho-quick-actions-entry.XXXXXX)"
cp "$entry" "$backup_file"
cleanup() {
  cp "$backup_file" "$entry"
  rm -f "$backup_file"
  if [[ -n "$fixture_pid" ]]; then kill "$fixture_pid" 2>/dev/null || true; fi
}
trap cleanup EXIT

build_app() {
  xcodebuild -skipMacroValidation -project "$repo_dir/app/VroomVroom.xcodeproj" \
    -scheme VroomVroom -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$derived_dir" -clonedSourcePackagesDirPath "$derived_dir/SourcePackages" \
    -disableAutomaticPackageResolution -onlyUsePackageVersionsFromResolvedFile -jobs 2 \
    ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO \
    'OTHER_SWIFT_FLAGS=$(inherited) -j2' build
}

cp "$evidence_dir/PreviewHarness.swift" "$entry"
build_app > /tmp/landinho-quick-actions-harness-build.log 2>&1
app_dir="$derived_dir/Build/Products/Debug-iphonesimulator/VroomVroom.app"
xcrun simctl install "$simulator_id" "$app_dir"
python3 -u "$repo_dir/docs/evidence/deep-links/fixture.py" > /tmp/landinho-quick-actions-fixture.log 2>&1 &
fixture_pid=$!
sleep 1
kill -0 "$fixture_pid"
curl --fail --silent http://127.0.0.1:18084/category > /dev/null

launch_mode() {
  SIMCTL_CHILD_LANDINHO_API_URL=http://127.0.0.1:18084 \
    SIMCTL_CHILD_LANDINHO_QUICK_ACTION_EVIDENCE="$1" \
    xcrun simctl launch --terminate-running-process \
      --stdout="/tmp/landinho-quick-actions-$1.stdout" \
      --stderr="/tmp/landinho-quick-actions-$1.stderr" \
      "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)'
}
capture() {
  xcrun simctl io "$simulator_id" screenshot "$evidence_dir/$1.png"
  sips -s format jpeg -s formatOptions 80 "$evidence_dir/$1.png" \
    --out "$evidence_dir/$1.jpg" > /dev/null
  rm "$evidence_dir/$1.png"
}

container_dir="$(xcrun simctl get_app_container "$simulator_id" "$bundle_id" data)"
rm -f "$container_dir/Documents/quick-actions-tests.json"
launch_mode tests
sleep 3
cp "$container_dir/Documents/quick-actions-tests.json" "$evidence_dir/native-tests.json"
python3 -c '
import json, sys
report = json.load(open(sys.argv[1]))
assert report["count"] == 6 and report["failures"] == 0, report
print("Native quick actions: 6 tests, 0 failures")
' "$evidence_dir/native-tests.json"

launch_mode warm-settings
sleep 3
capture before-warm-settings
sleep 7
capture after-warm-settings

launch_mode cold-categories
sleep 3
capture after-startup-categories
launch_mode cold-settings
sleep 3
capture after-startup-settings

launch_mode warm-home
sleep 3
capture before-warm-home
sleep 7
capture after-warm-home

launch_mode beta
sleep 3
capture beta-queued
sleep 13
capture beta-delivered

launch_mode unknown
sleep 10
capture unknown-stays-home

# Restore the ordinary app entry, build all scheme dependencies, and reinstall it.
cp "$backup_file" "$entry"
build_app > /tmp/landinho-quick-actions-shipping-build.log 2>&1
xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
xcrun simctl install "$simulator_id" "$app_dir"
git -C "$repo_dir" diff --quiet -- "$entry"
printf '%s\n' "Evidence captured; the restored shipping build is installed on $simulator_id."
