# Siri schedule evidence

This folder contains a read-only local API fixture and a temporary native app
entry for exercising the production App Intents. `PreviewHarness.swift` calls
the committed `perform()` methods, resolves F1 through the real category entity
query, and renders the production `RacingScheduleSnippet` using the exact returned
text. Its error screen displays the actual thrown `LocalizedError` text.

The harness is not part of an app target. It temporarily replaces only
`app/VroomVroom/VroomVroomApp.swift`; the ordinary entry must be restored before
the final shipping build. The Settings scenario presents the production
`SettingsView`. A before capture can temporarily use its exact source from the
parent `feature/session-notifications` commit without changing the harness.

These are direct native App Intent executions, not spoken Siri or an installed
saved shortcut running in the Shortcuts app. Device-agent interaction is disabled
in this environment. Apple's documented `shortcuts://run-shortcut` URL requires
a shortcut in the user's saved collection; it does not establish that either
App Shortcut ran. No private interaction or permission mechanism is used.

## App schema decision and localization

The Xcode 27.1 SDK and current Apple references were inspected before choosing
the integration. `@AppIntent(schema:)` is available from iOS 18. The current
calendar intent schemas are iOS 27 and create, update, or delete events. The
calendar event entity requires known start and end dates; our calendars can have
pending starts and do not provide session end times. `system.searchInApp` opens
search results. The read-only schedule reply uses ordinary App Intents and App
Shortcuts, preserving the app's iOS 17 baseline.

Sources: [calendar schemas](https://developer.apple.com/documentation/appintents/app-schema-domain-calendar),
[calendar event entity](https://developer.apple.com/documentation/appintents/appschema/calendarentity/event),
and [system search schema](https://developer.apple.com/documentation/appintents/appschema/systemintent/searchinapp).

The app's development localization and the `AppShortcuts.xcstrings` source
language are `pt-BR`, matching the existing Portuguese content. All five phrase
templates retain the framework's application and category placeholders. Apple
describes this catalog workflow in
[Spotlight your app with App Shortcuts](https://developer.apple.com/videos/play/wwdc2023/10102/).
`verify-metadata.py` checks the compiled Portuguese phrase resource, both action
identifiers, the main action's `race` default, optional category input, the extracted phrase templates and SSU
training locale, and the embedded Widget and App Clip. Native result JSON also
records `Bundle.main.localizations` and `developmentLocalization`.

## Reproduction

With the sole build/simulator lease and an initialized task-owned simulator:

```sh
python3 docs/evidence/siri-schedule/fixture-server.py
# Temporarily use PreviewHarness.swift as the app entry and build the app.
# After installing an evidence build, capture.sh uses the exact UDID:
bash docs/evidence/siri-schedule/capture.sh EXACT_UDID EVIDENCE_APP_PATH race
```

Query scenarios are `race`, `session`, `category`, `pending`, `cancelled`, `empty`,
and `offline` (a real fixture HTTP 503). Settings scenarios are `before-settings`
and `after-settings`; appearance is an optional fourth argument, `light` or
`dark`. The fixture returns one round per page so that the next main race lives
on page two. It returns only public category and calendar reads.

Each query writes its actual result to the app's Documents folder; the capture
script saves and checks that JSON before taking an exact-UDID simulator screenshot.
JPEG compression changes file size, not the rendered SwiftUI layout.

After restoring the ordinary entry and any baseline Settings source, build the
shipping app and run:

```sh
python3 docs/evidence/siri-schedule/verify-metadata.py SHIPPING_APP_PATH
```

For an incremental Xcode build, changing an intent can rewrite its metadata
directory while the SSU training task remains cached. Touch the AppShortcuts
catalog before the final build to regenerate the training assets; verification
requires the final bundle to contain those assets for the current action names.

## Recorded validation

Recorded on 01/10/2026 on the initialized task-owned iPhone 17 simulator
`B741BA8C-47CD-4105-A6E6-98ADF0946FEF`, iOS 27.0, using Xcode 27.1:

- All 52 Foundation tests passed, including 18 Siri query/loading tests. These
  cover cross-round ordering, main race versus all sessions, category filtering,
  pending dates and time zones, cancellation, incomplete/duplicate/changing
  pagination, network failure and the 50-page limit.
- Native `perform()` calls passed all seven fixture scenarios. The race response
  selected Stock Car from page two; the separate session action returned F1
  practice. Category selection used `RacingCategoryQuery.entities(matching:)`.
  Actual results are saved as `*-result.json`; `fixture-requests.log` records
  the corresponding read-only HTTP requests.
- Ten actual simulator captures show the seven results, the pending snippet in
  dark mode, and Settings before/after. `harness-before-settings-light.jpg` uses
  the exact parent Settings source at
  `33341cf9a37f9f12d8da7d3600e77aa156929325`; the after capture uses this change's
  production Settings source. The error capture is the actual HTTP 503 error
  text presented by the harness, not a Siri system error screen.
- The ordinary app entry and final Settings source were restored. The shipping
  app, Widget and embedded App Clip build passed. Fresh metadata extraction,
  compiled `pt-BR` phrases and SSU training verification passed; see
  `metadata-verification.json`. The shipping app was installed after verification.

Commands used for the tests and final shipping build:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --package-path app/LandinhoFoundation --jobs 2
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -skipMacroValidation -disableAutomaticPackageResolution \
  -project app/VroomVroom.xcodeproj -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=B741BA8C-47CD-4105-A6E6-98ADF0946FEF' \
  -derivedDataPath /tmp/landinho-about-developer-derived -jobs 2 \
  'OTHER_SWIFT_FLAGS=$(inherited) -j2' ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  CODE_SIGNING_ALLOWED=NO build
```

These results validate direct native execution and extracted discovery metadata.
Spoken Siri, a saved Shortcut, and the system-hosted Siri snippet were not
executed. The Settings screenshot confirms the public `ShortcutsLink` render;
its tap was not automated. No private API or disabled device interaction was used.
