#!/bin/bash
set -euo pipefail
simulator_id="${1:?Usage: capture.sh IPAD_SIMULATOR_UDID [before|after] [scenario]}"
mode="${2:-after}"
scenario="${3:-standard}"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
evidence_dir="$repo_dir/docs/evidence/extra-large-widget"
build_dir="/tmp/landinho-extra-large-evidence-$mode"
app_dir="$build_dir/ExtraLargeEvidence.app"
sdk_path="$(xcrun --sdk iphonesimulator --show-sdk-path)"
mkdir -p "$app_dir"

if [[ "$mode" == before ]]; then
  git archive 4ff8bc0 app/LandinhoFoundation/Sources app/LandinhoCoreUI/Sources/WidgetUI app/LandinhoCoreUI/Sources/CategoryUI app/Widgets/NextRaceWidget/NextRaceWidget.swift | tar -x -C "$build_dir"
  source_dir="$build_dir"
else
  source_dir="$repo_dir"
fi
# Compile the exact production family switch without extension/timeline dependencies.
{
  printf '%s\n' 'import Foundation' 'import SwiftUI' 'import WidgetKit' 'import WidgetUI' 'import LandinhoFoundation'
  sed -n '/^struct NextRaceWidgetView: View {/,/^\/\/ MARK: - Previews/{ /^\/\/ MARK/d; p; }' \
    "$source_dir/app/Widgets/NextRaceWidget/NextRaceWidget.swift"
} > "$build_dir/FamilyDispatcher.swift"
compiler=(xcrun --sdk iphonesimulator swiftc -j2 -sdk "$sdk_path" -target arm64-apple-ios17.0-simulator -parse-as-library -I "$build_dir" -L "$app_dir")
"${compiler[@]}" -emit-library -emit-module -module-name LandinhoFoundation \
  -emit-module-path "$build_dir/LandinhoFoundation.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libLandinhoFoundation.dylib \
  "$source_dir"/app/LandinhoFoundation/Sources/LandinhoFoundation/*.swift -o "$app_dir/libLandinhoFoundation.dylib"
"${compiler[@]}" -emit-library -emit-module -module-name CategoryUI -lLandinhoFoundation \
  -emit-module-path "$build_dir/CategoryUI.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libCategoryUI.dylib \
  "$source_dir"/app/LandinhoCoreUI/Sources/CategoryUI/*.swift -o "$app_dir/libCategoryUI.dylib"
"${compiler[@]}" -emit-library -emit-module -module-name WidgetUI -lLandinhoFoundation -lCategoryUI \
  -emit-module-path "$build_dir/WidgetUI.swiftmodule" \
  -Xlinker -install_name -Xlinker @rpath/libWidgetUI.dylib \
  "$source_dir"/app/LandinhoCoreUI/Sources/WidgetUI/NextRace/*.swift \
  "$source_dir/app/LandinhoCoreUI/Sources/WidgetUI/WidgetBackground.swift" -o "$app_dir/libWidgetUI.dylib"
"${compiler[@]}" "$evidence_dir/PreviewHarness.swift" "$build_dir/FamilyDispatcher.swift" \
  -lLandinhoFoundation -lCategoryUI -lWidgetUI -Xlinker -rpath -Xlinker @executable_path -o "$app_dir/ExtraLargeEvidence"

bundle_id="com.landinho.ExtraLargeEvidence.$mode"
cat > "$app_dir/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>$bundle_id</string>
<key>CFBundleExecutable</key><string>ExtraLargeEvidence</string>
<key>CFBundleName</key><string>ExtraLargeEvidence</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSRequiresIPhoneOS</key><true/>
<key>UILaunchScreen</key><dict/>
<key>UIDeviceFamily</key><array><integer>2</integer></array>
<key>UISupportedInterfaceOrientations</key><array><string>UIInterfaceOrientationPortrait</string></array>
</dict></plist>
PLIST
xcrun simctl install "$simulator_id" "$app_dir"
xcrun simctl terminate "$simulator_id" "$bundle_id" 2>/dev/null || true
xcrun simctl launch "$simulator_id" "$bundle_id" -AppleLocale pt_BR -AppleLanguages '(pt-BR)' "$scenario"
sleep 3
xcrun simctl io "$simulator_id" screenshot "$evidence_dir/$mode-$scenario.png"
sips -s format jpeg -s formatOptions 80 "$evidence_dir/$mode-$scenario.png" --out "$evidence_dir/$mode-$scenario.jpg" >/dev/null
rm "$evidence_dir/$mode-$scenario.png"
