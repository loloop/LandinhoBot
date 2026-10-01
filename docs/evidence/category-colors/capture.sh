#!/bin/bash
set -euo pipefail

simulator_id="${1:?Usage: capture.sh SIMULATOR_UDID [before|after]}"
mode="${2:-after}"
[[ "$mode" == before || "$mode" == after ]]
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/category-colors"
backup_dir="$(mktemp -d /tmp/landinho-category-color-source.XXXXXX)"
entry="app/VroomVroom/VroomVroomApp.swift"
sources=(
  "$entry"
  app/LandinhoLib/Sources/Categories/Categories.swift
  app/LandinhoLib/Sources/CategoriesAdmin/CategoryEditor.swift
  app/LandinhoLib/Sources/CategoriesAdmin/Views/CategoryEditorView.swift
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
  for source in "${sources[@]:1}"; do git show "51cfad4:$source" > "$repo_dir/$source"; done
fi
cp "$evidence_dir/PreviewHarness.swift" "$repo_dir/$entry"
xcodebuild -jobs 4 -skipMacroValidation -project "$repo_dir/app/VroomVroom.xcodeproj" \
  -scheme VroomVroom -destination "platform=iOS Simulator,id=$simulator_id" \
  -derivedDataPath /tmp/landinho-category-colors-derived \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build \
  > "/tmp/landinho-category-colors-$mode-build.log" 2>&1

app_dir=/tmp/landinho-category-colors-derived/Build/Products/Debug-iphonesimulator/VroomVroom.app
bundle_id=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$app_dir/Info.plist")
xcrun simctl install "$simulator_id" "$app_dir"
xcrun simctl status_bar "$simulator_id" override --time '9:41' --dataNetwork wifi --wifiMode active --wifiBars 3 --batteryState charged --batteryLevel 100
for scenario in categories editor; do
  xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
  xcrun simctl launch "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)' "$scenario"
  sleep 3
  xcrun simctl io "$simulator_id" screenshot "$evidence_dir/$mode-$scenario.png"
  sips -s format jpeg -s formatOptions 80 "$evidence_dir/$mode-$scenario.png" --out "$evidence_dir/$mode-$scenario.jpg" >/dev/null
  rm "$evidence_dir/$mode-$scenario.png"
done
if [[ "$mode" == after ]]; then
  xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
  xcrun simctl launch "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)' editor dark
  sleep 3
  xcrun simctl io "$simulator_id" screenshot "$evidence_dir/after-editor-dark.png"
  sips -s format jpeg -s formatOptions 80 "$evidence_dir/after-editor-dark.png" --out "$evidence_dir/after-editor-dark.jpg" >/dev/null
  rm "$evidence_dir/after-editor-dark.png"
fi
