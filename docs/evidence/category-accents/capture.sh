#!/bin/bash
set -euo pipefail

simulator_id="${1:?Usage: capture.sh SIMULATOR_UDID [before|after]}"
mode="${2:-after}"
[[ "$mode" == before || "$mode" == after ]]
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/category-accents"
derived_dir="${CATEGORY_ACCENT_DERIVED_DATA:-/tmp/landinho-category-colors-derived}"
base_ref="${CATEGORY_ACCENT_BASE_REF:-$(git merge-base HEAD feature/deep-links)}"
backup_dir="$(mktemp -d /tmp/landinho-category-accent-source.XXXXXX)"
entry="app/VroomVroom/VroomVroomApp.swift"
sources=(
  "$entry"
  app/LandinhoCore/Sources/EventDetail/EventDetail.swift
  app/LandinhoLib/Sources/Categories/Categories.swift
  app/LandinhoCoreUI/Sources/WidgetUI/NextRace/NextRaceSmallWidgetView.swift
  app/LandinhoCoreUI/Sources/WidgetUI/NextRace/NextRaceMediumWidgetView.swift
  app/LandinhoCoreUI/Sources/WidgetUI/NextRace/NextRaceLargeWidgetView.swift
)
restore_sources() {
  for source in "${sources[@]}"; do cp "$backup_dir/$source" "$repo_dir/$source"; done
  rm -rf "$backup_dir"
}
trap restore_sources EXIT
for source in "${sources[@]}"; do
  mkdir -p "$backup_dir/$(dirname "$source")"
  cp "$repo_dir/$source" "$backup_dir/$source"
done
if [[ "$mode" == before ]]; then
  for source in "${sources[@]:1}"; do git show "$base_ref:$source" > "$repo_dir/$source"; done
fi
cp "$evidence_dir/PreviewHarness.swift" "$repo_dir/$entry"
xcodebuild -jobs 2 'OTHER_SWIFT_FLAGS=$(inherited) -j2' -skipMacroValidation -disableAutomaticPackageResolution -skipPackageUpdates \
  -project "$repo_dir/app/VroomVroom.xcodeproj" \
  -scheme VroomVroom -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath "$derived_dir" \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build \
  > "/tmp/landinho-category-accents-$mode-build.log" 2>&1

app_dir="$derived_dir/Build/Products/Debug-iphonesimulator/VroomVroom.app"
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_dir/Info.plist")
xcrun simctl install "$simulator_id" "$app_dir"
xcrun simctl status_bar "$simulator_id" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
for scenario in schedule detail categories widgets sharing; do
  for appearance in light dark; do
    # Both widget appearances are covered by schedule; one focused size capture suffices.
    [[ "$scenario" == widgets && "$appearance" == dark ]] && continue
    [[ "$scenario" == sharing && "$appearance" == dark ]] && continue
    xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
    xcrun simctl launch "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)' "$scenario" "$appearance"
    sleep 3
    image_file="$evidence_dir/$mode-$scenario-$appearance"
    xcrun simctl io "$simulator_id" screenshot "$image_file.png"
    sips -s format jpeg -s formatOptions 80 "$image_file.png" --out "$image_file.jpg" >/dev/null
    rm "$image_file.png"
  done
done
