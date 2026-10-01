#!/bin/bash
set -euo pipefail

# Requires an already booted, task-owned simulator and the shared build lease.
# This script never boots a simulator or changes the shipping app's sources.
simulator_id="${1:?Usage: capture.sh SIMULATOR_UDID [before|after] [options|text|sheet] [BEFORE_REF]}"
mode="${2:-after}"
scenario="${3:-options}"
before_ref="${4:-feature/quick-actions}"
[[ "$mode" == before || "$mode" == after ]]
[[ "$scenario" == options || "$scenario" == text || "$scenario" == sheet ]]
if [[ "$mode" == before && "$scenario" != options ]]; then
  echo 'The before branch has no text action; capture its options only.' >&2
  exit 1
fi

export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/text-sharing"
build_dir="/tmp/landinho-text-sharing-evidence-$mode"
app_dir="$build_dir/TextSharingEvidence.app"
sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
mkdir -p "$app_dir"

if [[ "$mode" == before ]]; then
  git archive "$before_ref" app/LandinhoFoundation/Sources | tar -x -C "$build_dir"
  git show "$before_ref:app/LandinhoCore/Sources/EventDetail/EventDetail.swift" > "$build_dir/BeforeEventDetail.swift"
  # Extract the baseline's exact link/image action content; replace only the TCA
  # image delegate call with the harness closure. No rendered menu is fabricated.
  python3 - "$build_dir/BeforeEventDetail.swift" "$build_dir/RoundShareActions.swift" <<'PY'
import pathlib
import sys
source = pathlib.Path(sys.argv[1]).read_text()
toolbar = source[source.index('    .toolbar {'):]
start = toolbar.index('        Menu {\n') + len('        Menu {\n')
end = toolbar.index('\n        } label: {', start)
actions = toolbar[start:end]
assert 'Compartilhar link' in actions and 'Compartilhar imagem' in actions
assert 'Compartilhar texto' not in actions
actions = actions.replace('store.send(.delegate(.onShareTap(race: race)))', 'onShareImage()')
pathlib.Path(sys.argv[2]).write_text('''import LandinhoFoundation
import SwiftUI
struct RoundShareActions: View {
  let race: Race
  let onShareImage: () -> Void
  var body: some View {
''' + actions + '\n  }\n}\n')
PY
  source_dir="$build_dir"
  menu_source="$build_dir/RoundShareActions.swift"
  define=(-D BEFORE)
else
  source_dir="$repo_dir"
  menu_source="$repo_dir/app/LandinhoCore/Sources/EventDetail/RoundShareMenu.swift"
  define=(-D AFTER)
fi

compiler=(xcrun --sdk iphonesimulator swiftc -j2 -sdk "$sdk_path" -target arm64-apple-ios17.0-simulator -parse-as-library -I "$build_dir" -L "$app_dir")
"${compiler[@]}" -emit-library -emit-module -module-name LandinhoFoundation \
  -emit-module-path "$build_dir/LandinhoFoundation.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libLandinhoFoundation.dylib \
  "$source_dir"/app/LandinhoFoundation/Sources/LandinhoFoundation/*.swift -o "$app_dir/libLandinhoFoundation.dylib"
"${compiler[@]}" "${define[@]}" "$evidence_dir/PreviewHarness.swift" "$menu_source" \
  -lLandinhoFoundation -Xlinker -rpath -Xlinker @executable_path -o "$app_dir/TextSharingEvidence"

bundle_id="com.landinho.TextSharingEvidence.$mode"
cat > "$app_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$bundle_id</string>
<key>CFBundleExecutable</key><string>TextSharingEvidence</string>
<key>CFBundleName</key><string>TextSharingEvidence</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSRequiresIPhoneOS</key><true/>
<key>UILaunchScreen</key><dict/>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
</dict></plist>
PLIST

xcrun simctl install "$simulator_id" "$app_dir"
xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
SIMCTL_CHILD_TZ=America/Sao_Paulo xcrun simctl launch "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)' "$scenario"
sleep 4
xcrun simctl io "$simulator_id" screenshot "$evidence_dir/$mode-$scenario.png"
sips -s format jpeg -s formatOptions 80 "$evidence_dir/$mode-$scenario.png" --out "$evidence_dir/$mode-$scenario.jpg" >/dev/null
rm "$evidence_dir/$mode-$scenario.png"
