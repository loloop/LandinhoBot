#!/bin/bash
set -euo pipefail
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer
repo_dir="$(git rev-parse --show-toplevel)"
build_dir="$(mktemp -d /tmp/landinho-extra-large-tests.XXXXXX)"
trap 'rm -rf "$build_dir"' EXIT
xctest_dir="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/Library/Frameworks"
xctest_swift_dir="$DEVELOPER_DIR/Platforms/MacOSX.platform/Developer/usr/lib"
compiler=(xcrun swiftc -j2 -I "$build_dir" -L "$build_dir" -F "$xctest_dir" -I "$xctest_swift_dir" -L "$xctest_swift_dir")
"${compiler[@]}" -parse-as-library -emit-library -emit-module -module-name LandinhoFoundation \
  "$repo_dir"/app/LandinhoFoundation/Sources/LandinhoFoundation/*.swift \
  -o "$build_dir/libLandinhoFoundation.dylib"
# This dependency-free slice exercises the production presentation model with XCTest.
"${compiler[@]}" -parse-as-library -emit-library -emit-module -enable-testing -module-name WidgetUI \
  "$repo_dir/app/LandinhoCoreUI/Sources/WidgetUI/NextRace/WidgetScheduleContent.swift" \
  "$repo_dir/app/LandinhoCoreUI/Sources/WidgetUI/NextRace/ExtraLargeWidgetSchedule.swift" \
  -lLandinhoFoundation -o "$build_dir/libWidgetUI.dylib"
cat > "$build_dir/main.swift" <<'SWIFT'
import XCTest
let suite = XCTestSuite(forTestCaseClass: ExtraLargeWidgetScheduleTests.self)
suite.run()
let result = suite.testRun!
print("Executed \(result.executionCount) tests, \(result.totalFailureCount) failures")
exit(result.totalFailureCount == 0 && result.executionCount == 4 ? 0 : 1)
SWIFT
"${compiler[@]}" "$repo_dir/app/LandinhoCoreUI/Tests/WidgetUITests/ExtraLargeWidgetScheduleTests.swift" \
  "$build_dir/main.swift" -lLandinhoFoundation -lWidgetUI -Xlinker -rpath -Xlinker "$xctest_dir" \
  -Xlinker -rpath -Xlinker "$xctest_swift_dir" -o "$build_dir/tests"
DYLD_LIBRARY_PATH="$build_dir" "$build_dir/tests"
