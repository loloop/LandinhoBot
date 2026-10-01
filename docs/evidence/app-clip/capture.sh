#!/bin/bash
# Run only while holding the team's sole build/simulator lease. Uses a previously
# initialized task-owned device; native interactions are disabled in this setup.
set -euo pipefail
: "${LANDINHO_EVIDENCE_SIMULATOR:?Set an exact root-approved task-owned simulator UDID}"
: "${LANDINHO_EVIDENCE_DERIVED:?Set a root-approved app-pinned DerivedData cache}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_dir"
simulator_id=$LANDINHO_EVIDENCE_SIMULATOR
derived_dir=$LANDINHO_EVIDENCE_DERIVED
clip_entry=app/VroomVroomClip/VroomVroomClipApp.swift
app_entry=app/VroomVroom/VroomVroomApp.swift
scratch_dir=$(mktemp -d /tmp/landinho-app-clip-capture.XXXXXX)
cp "$clip_entry" "$scratch_dir/clip-entry.swift"
cp "$app_entry" "$scratch_dir/app-entry.swift"
fixture_pid=
restore() {
  cp "$scratch_dir/clip-entry.swift" "$clip_entry"
  cp "$scratch_dir/app-entry.swift" "$app_entry"
  if [[ -n "$fixture_pid" ]]; then kill "$fixture_pid" 2>/dev/null || true; fi
  xcrun simctl shutdown "$simulator_id" 2>/dev/null || true
}
trap restore EXIT
build() {
  local scheme=$1
  local log=$2
  xcodebuild -jobs 2 -skipMacroValidation -project app/VroomVroom.xcodeproj \
    -scheme "$scheme" -destination "platform=iOS Simulator,id=$simulator_id" \
    -derivedDataPath "$derived_dir" ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
    'OTHER_SWIFT_FLAGS=$(inherited) -j2' CODE_SIGNING_ALLOWED=NO build > "$log" 2>&1
}
capture() {
  local name=$1
  xcrun simctl io "$simulator_id" screenshot "$scratch_dir/$name.png"
  sips -s format jpeg -s formatOptions 82 "$scratch_dir/$name.png" \
    --out "docs/evidence/app-clip/$name.jpg" >/dev/null
}
clip_mode() {
  local mode=$1
  xcrun simctl terminate "$simulator_id" me.mauriciocardozo.racing.vroomvroom.Clip 2>/dev/null || true
  SIMCTL_CHILD_LANDINHO_API_URL=http://127.0.0.1:18085 \
  SIMCTL_CHILD_LANDINHO_CLIP_EVIDENCE="$mode" xcrun simctl launch "$simulator_id" \
    me.mauriciocardozo.racing.vroomvroom.Clip
}
python3 docs/evidence/app-clip/fixture.py > "$scratch_dir/fixture.log" 2>&1 &
fixture_pid=$!
# Target changes, network and UI are the shipping implementations. Only entries
# synthesize the user activity or show the native share payload for screenshots.
cp docs/evidence/app-clip/ClipHarness.swift "$clip_entry"
build VroomVroomClip "$scratch_dir/clip-harness-build.log"
xcrun simctl boot "$simulator_id" || true
xcrun simctl bootstatus "$simulator_id" -b
xcrun simctl ui "$simulator_id" appearance dark
xcrun simctl uninstall "$simulator_id" me.mauriciocardozo.racing.vroomvroom 2>/dev/null || true
xcrun simctl install "$simulator_id" "$derived_dir/Build/Products/Debug-iphonesimulator/VroomVroomClip.app"
for mode in cold categories round restored invalid missing settings handoff handoff-native; do
  clip_mode "$mode"
  if [[ "$mode" == handoff* ]]; then sleep 15; else sleep 7; fi
  capture "clip-$mode"
done
clip_mode warm
sleep 5
capture clip-warm-before
sleep 9
capture clip-warm-after
# Restore the Clip before the full-app harness build to verify embedded shipping code.
cp "$scratch_dir/clip-entry.swift" "$clip_entry"
cp docs/evidence/app-clip/SettingsHarness.swift "$app_entry"
build VroomVroom "$scratch_dir/settings-harness-build.log"
xcrun simctl install "$simulator_id" "$derived_dir/Build/Products/Debug-iphonesimulator/VroomVroom.app"
for mode in settings share; do
  xcrun simctl terminate "$simulator_id" me.mauriciocardozo.racing.vroomvroom 2>/dev/null || true
  SIMCTL_CHILD_LANDINHO_API_URL=http://127.0.0.1:18085 \
  SIMCTL_CHILD_LANDINHO_SETTINGS_EVIDENCE="$mode" xcrun simctl launch "$simulator_id" \
    me.mauriciocardozo.racing.vroomvroom
  if [[ "$mode" == share ]]; then sleep 25; else sleep 9; fi
  capture "app-$mode"
done
cp "$scratch_dir/app-entry.swift" "$app_entry"
build VroomVroom "$scratch_dir/final-shipping-build.log"
xcrun simctl install "$simulator_id" "$derived_dir/Build/Products/Debug-iphonesimulator/VroomVroom.app"
xcrun simctl shutdown "$simulator_id"
echo "Evidence/build logs: $scratch_dir"
