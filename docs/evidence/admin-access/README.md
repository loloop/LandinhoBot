# Administration password evidence

These are actual iPhone 18 Pro / iOS 27.0 simulator screenshots of the production SwiftUI views, opened in a temporary native preview harness. They are not mockups. The harness drove the production Settings reducer actions rather than automating touches through Device Hub. The temporary entry point and baseline Settings source were restored before the final shipping build.

- Simulator: `7FFA0FA6-466B-44D5-A752-7DA7A2147FD6` (Landinho Admin Access), shut down after capture.
- `before-settings.jpg`: original Settings at base `bed1d8a`, with its visible Admin row.
- `after-settings.jpg`: Settings with administration hidden and the developer screen link preserved.
- `after-prompt.jpg`: the secure password prompt.
- `after-wrong.jpg`: a real HTTP 401 from the local backend produces the wrong-password message and keeps the prompt available for retry.
- `after-unlocked.jpg`: a real successful password verification opens category administration with a lock control.
- `after-background.jpg`: posting the real UIKit `didEnterBackgroundNotification` in the harness clears administration and returns to Settings. This is a simulated lifecycle notification, not a screenshot of the OS app switcher.

The after harness used `LANDINHO_API_URL=http://127.0.0.1:8086` against the Vapor backend, an isolated PostgreSQL cluster on port 55435, and a separate disposable `landinho_admin_evidence` database. Scheduled imports were disabled. It read the empty private import history after successful verification, then asserted that the same request returned HTTP 401 after explicit locking and after the background notification. No production APIs or Telegram bot were used. Long-press touch recognition and the VoiceOver custom action were compiled but not interactively exercised.

Validation:

- Backend: 25 XCTest cases passed after stacking category colors, zero failures/skips, including every administrative route with missing, malformed, wrong, valid, and unconfigured credentials; authorized edits; public calendars/subscriptions; removal of private import settings from public and nested category JSON, and preservation/editing of category colors through the protected API.
- Settings: four reducer tests passed on the iOS simulator, covering verification, wrong-password retry, unconfigured server, locking/cancellation, and discarded late responses.
- Credential storage: three XCTest cases passed using the actual committed source and tests in a tiny temporary Foundation-only Swift package harness. These cover administrative header scope, lock invalidation, and a later verified retry.
- The final normal app build passed after removing the temporary app entry point. Existing unrelated warnings remain (including extension/app build-number mismatch).

The screenshots were captured using the exact simulator UDID and converted to JPEG at quality 85 for repository size. The SwiftUI layout was not altered for capture.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -skipMacroValidation -disableAutomaticPackageResolution \
  -project app/VroomVroom.xcodeproj -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=7FFA0FA6-466B-44D5-A752-7DA7A2147FD6' \
  -derivedDataPath /tmp/landinho-admin-access-derived \
  -clonedSourcePackagesDirPath /tmp/landinho-admin-source-packages \
  -jobs 2 'OTHER_SWIFT_FLAGS=$(inherited) -j2' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl io \
  7FFA0FA6-466B-44D5-A752-7DA7A2147FD6 screenshot /tmp/capture.png
```

## Merge with main on 01/10/2026

The resolution preserves the offline `VroomVroomMock` target from main and the Home/favorites work already merged into this PR. Both `MockAPIClient` and `CategoryFavorites` remain exported package products. The mock integration test now follows the current paginated `ScheduleList` actions. Admin verification resolves the injected `apiRequester`; the separate mock service handles `admin-session` in memory and accepts any nonempty password without contacting the hosted API.

A fresh `LandinhoCore-Package` run on the task-owned iPhone 17 simulator (`B741BA8C-47CD-4105-A6E6-98ADF0946FEF`, iOS 27.0) passed 18 tests with zero failures: 9 mock integration tests, 6 Home tests, and 3 credential-store tests. This includes `testAdminVerificationUsesTheInjectedMock` and `testScheduleReducerLoadsThroughTheInjectedMock`. The tracked Core lockfile from main retains the app's TCA 1.11.2 / Collections 1.1.1 pins.

```sh
cd app/LandinhoCore
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -skipMacroValidation -disableAutomaticPackageResolution \
  -scheme LandinhoCore-Package \
  -destination 'platform=iOS Simulator,id=B741BA8C-47CD-4105-A6E6-98ADF0946FEF' \
  -derivedDataPath /tmp/landinho-admin-access-derived \
  -clonedSourcePackagesDirPath /tmp/landinho-admin-source-packages \
  -parallel-testing-enabled NO -jobs 2 \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO test
```

Fresh simulator builds of both `VroomVroomMock` and the normal `VroomVroom` app (including its widget extension) passed after the merge. Builds used the project/scheme, the same derived-data and package-cache paths above, `-destination 'generic/platform=iOS Simulator'`, `-jobs 2`, `ARCHS=arm64`, `ONLY_ACTIVE_ARCH=YES`, and `CODE_SIGNING_ALLOWED=NO`.

The existing screenshots above document the unchanged admin flow; this merge resolution did not recapture them.
