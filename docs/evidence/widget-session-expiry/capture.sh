#!/bin/bash
set -euo pipefail

# Pass an explicitly created/booted simulator UDID; no shared foreground UI needed.
simulator_id="${1:?Usage: capture.sh SIMULATOR_UDID [before|after] [scenario]}"
mode="${2:-after}"
scenario="${3:-upcoming}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/widget-session-expiry"
build_dir="/tmp/landinho-widget-evidence-$mode"
app_dir="$build_dir/WidgetEvidence.app"
sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
mkdir -p "$app_dir"

if [[ "$mode" == before ]]; then
  git archive 14f47b9 app/LandinhoFoundation/Sources app/LandinhoCoreUI/Sources/WidgetUI | tar -x -C "$build_dir"
  source_dir="$build_dir"
  define=(-D BEFORE)
else
  source_dir="$repo_dir"
  define=(-D AFTER)
fi

foundation_sources=("$source_dir"/app/LandinhoFoundation/Sources/LandinhoFoundation/*.swift)
widget_sources=("$source_dir"/app/LandinhoCoreUI/Sources/WidgetUI/NextRace/*.swift "$source_dir"/app/LandinhoCoreUI/Sources/WidgetUI/WidgetBackground.swift)
compiler=(xcrun --sdk iphonesimulator swiftc -sdk "$sdk_path" -target arm64-apple-ios17.0-simulator -parse-as-library -I "$build_dir" -L "$app_dir")

"${compiler[@]}" -emit-library -emit-module -module-name LandinhoFoundation \
  -emit-module-path "$build_dir/LandinhoFoundation.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libLandinhoFoundation.dylib \
  "${foundation_sources[@]}" -o "$app_dir/libLandinhoFoundation.dylib"
"${compiler[@]}" -emit-library -emit-module -module-name WidgetUI -lLandinhoFoundation \
  -emit-module-path "$build_dir/WidgetUI.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libWidgetUI.dylib \
  "${widget_sources[@]}" -o "$app_dir/libWidgetUI.dylib"
"${compiler[@]}" "${define[@]}" "$evidence_dir/PreviewHarness.swift" -lLandinhoFoundation -lWidgetUI \
  -Xlinker -rpath -Xlinker @executable_path -o "$app_dir/WidgetEvidence"

bundle_id="com.landinho.WidgetSessionEvidence.$mode"
cat > "$app_dir/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$bundle_id</string>
<key>CFBundleExecutable</key><string>WidgetEvidence</string>
<key>CFBundleName</key><string>WidgetEvidence</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSRequiresIPhoneOS</key><true/>
<key>UILaunchScreen</key><dict/>
<key>UIDeviceFamily</key><array><integer>1</integer></array>
</dict></plist>
EOF
xcrun simctl install "$simulator_id" "$app_dir"
xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
xcrun simctl launch "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)' "$scenario"
sleep 3
xcrun simctl io "$simulator_id" screenshot "$evidence_dir/$mode-$scenario.png"
sips -s format jpeg -s formatOptions 80 "$evidence_dir/$mode-$scenario.png" --out "$evidence_dir/$mode-$scenario.jpg" >/dev/null
rm "$evidence_dir/$mode-$scenario.png"
