# Session start reminders: native evidence

Captured on 2026-10-01 using the task-owned iPhone 17 / iOS 27.0 simulator
`B741BA8C-47CD-4105-A6E6-98ADF0946FEF`, in Portuguese and dark appearance.
These are actual SwiftUI renders of the production EventDetail view, reducer, and
SessionReminderCenter, installed through a temporary native evidence entry.
The baseline is the parent `5c10c6b4af9f53006338fd656bd10bb30fe38592`
EventDetail source with symbol renames only. The shipping app entry is restored
after capture; the evidence entry is excluded from the final shipping build.

| Capture | What it demonstrates | Backend / action |
| --- | --- | --- |
| [before-detail.jpg](before-detail.jpg) | Parent round detail without reminder controls | Parent source |
| [after-off.jpg](after-off.jpg) | Reminder controls for known future times; cancelled/pending sessions have none | Injected allowed backend |
| [after-on.jpg](after-on.jpg) | Selected session becomes enabled after a successful schedule | Injected allowed backend |
| [after-cancel.jpg](after-cancel.jpg) | Toggling an existing reminder restores the inactive control | Injected allowed backend |
| [after-denied.jpg](after-denied.jpg) | Recoverable denial and notification-settings link | Injected denied backend |
| [native-provisional-awaiting.jpg](native-provisional-awaiting.jpg) | A later repeat settings read still in flight; this is not an enabled state | Native backend diagnostic |
| [native-permission-prompt.jpg](native-permission-prompt.jpg) | Actual iOS Allow / Don't Allow permission dialog | Shipping alert/sound request; left unanswered |

Native device interaction tools are disabled in this environment. The harness
sends the same production reducer action as the reminder button. No native tap,
settings navigation, or permission choice is claimed. Injected state screenshots
cannot prove an iOS permission grant or delivery. The prompt is captured last
because iOS can retain an unanswered sheet above subsequent launches; only the
task-owned simulator was restarted to clear an earlier sheet before recapture.

## Real native scheduling and delivery

The evidence-only setup uses Apple's public
[provisional authorization](https://developer.apple.com/documentation/usernotifications/unauthorizationoptions/provisional)
API, which grants noninterrupting Notification Center delivery without displaying
a permission sheet. This is separate from the unchanged shipping request for
`.alert` and `.sound`, made only after a session opt-in. Apple's
[permission documentation](https://developer.apple.com/documentation/usernotifications/asking-permission-to-use-notifications)
describes both paths. No private permission stores were modified.

All five native records have an empty `failures` array and actual system
authorization raw value `3` (provisional):

- [native-scheduled.json](native-scheduled.json): exactly the opted-in session is
  pending, with a nonrepeating Gregorian UTC trigger at its expected start.
- [native-rescheduled.json](native-rescheduled.json): a refreshed source time
  replaces the same request ID at a start 10 seconds later.
- [native-cancelled.json](native-cancelled.json): manual toggle of a second session
  removes only that reminder and preserves the first.
- [native-source-cancelled.json](native-source-cancelled.json): an explicitly
  cancelled session in a supplied refreshed round is removed.
- [native-delivery.json](native-delivery.json): `deliveredNotifications()` reports
  the first request's exact ID, session title, category/round body, and delivery
  epoch matching its rescheduled start; no session requests remain pending.

The passing native run was recorded before the button label and screenshot-order
adjustment. Its original start was `2026-10-01T12:05:37Z` (epoch `1790856337`);
its updated start and observed delivery were `2026-10-01T12:05:47Z`
(epoch `1790856347`). These JSON files remain the passing native backend evidence.
The evidence app remained running while delivery was inspected through the public
native API. No banner, sound, lock-screen presentation, or answered alert permission
prompt was observed. Its screenshots were obscured by the earlier unanswered
permission sheet and are intentionally excluded.

The [permission phases](native-permission-phases.json) record the real shipping
request and intentionally end at the unanswered dialog. The first diagnostic
settings read took about 66 seconds on the busy host. After the task-owned restart,
a repeat settings read stalled again with the app active and reached the bounded
capture deadline without scheduling; [waiting phases](native-provisional-waiting-phases.json)
and the explicitly labeled waiting image preserve that separate unsuccessful
repeat. The successful runtime JSON and corrected injected state images come
from distinct runs; the label adjustment did not change scheduling logic.

The five `injected-*.json` records verify zero permission requests during reads,
one addition for opt-in, one removal for cancellation, and no scheduled reminder
after denial. Fixture times are relative to capture time, not hardcoded past dates.

## Validation and reproduction

The native LandinhoCore test suite passed **31 tests, zero failures**: 7
EventDetail, 9 ScheduleList, 12 SessionReminders, and 3 AdminSession tests. This
covers refresh ordering, stale/malformed page rejection, fetched/preloaded detail,
permission denial and retry, precise UTC/DST triggers, cancellation, failed
reschedules, capacity, and concurrent toggles. The 12 dependency-free scheduler
tests also passed before native integration. No additional reducer run was needed
for the explicit `Color.primary` reminder label adjustment.

The evidence harness and final restored shipping build both succeeded. The built
app, widget extension, and embedded App Clip executables were verified; the
restored shipping app was installed on the task simulator, then that device was
shut down. Both builds use:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -jobs 2 -skipMacroValidation -disableAutomaticPackageResolution \
  -project app/VroomVroom.xcodeproj -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=B741BA8C-47CD-4105-A6E6-98ADF0946FEF' \
  -derivedDataPath /tmp/landinho-about-developer-derived \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  'OTHER_SWIFT_FLAGS=$(inherited) -j2' build
```

Run from the worktree root, with the approved device already booted and the sole
build/simulator lease available:

```sh
bash docs/evidence/session-notifications/prepare-source.sh install \
  5c10c6b4af9f53006338fd656bd10bb30fe38592
# Build the evidence entry with the command above.
bash docs/evidence/session-notifications/capture.sh \
  B741BA8C-47CD-4105-A6E6-98ADF0946FEF /tmp/landinho-about-developer-derived
bash docs/evidence/session-notifications/prepare-source.sh restore
# Build the restored shipping entry with the command above.
```

The capture script uses exact-UDID simctl operations and normal app reinstalls;
it never boots a device, changes private permissions, or touches other simulators.
State records are written to the installed app's Documents directory and copied
here; screenshots are compressed with `sips`. The Core test run temporarily used
the app's resolved dependency pins, then removed both generated Core pin files.

## Main integration validation (01/10/2026)

The published branch history was preserved with normal merges: the published
#36 resolution `d8942e1809cd418833153fd1d17890914f0d2c70`, then current main
`58889923d64193ddb8bb2c73beb266d0b457238c`, and finally main after #36 merged,
`5fdade7f8aaa3400e5da67a6f785b2e45344c5d0`. The Xcode project matches the #36
resolution, including normal app, widget, App Clip, and Mock target membership.
The dated in-app changelog retains the incoming history and API-domain maintenance
notes, adds notification behavior, and keeps completed feature TODOs removed.

The combined native Core suite passed **40 tests, zero failures**: the previous
31 tests plus 9 incoming MockAPIClient tests. The mock schedule integration now
records the reminder refresh, waits for the effect to finish, and asserts that the
exact loaded page is reconciled. Its test backend never calls native notification
APIs. The tracked Core dependency pins from main were preserved byte-for-byte.
An earlier compilation was cancelled before tests when the published #36
resolution arrived; only the complete combined run is counted here. The final
main merge changed only the changelog, so the unchanged Core tests were not
repeated. The normal app/widget/embedded App Clip build passed again after that
merge, and their executable membership was checked. The separate VroomVroomMock
build also passed; its distinct bundle ID, display name, executable, and absence
of the live widget extension were verified. The task simulator was shut down
after validation.

The complete run uses the same exact simulator and DerivedData as above, from
`app/LandinhoCore`:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -skipMacroValidation -disableAutomaticPackageResolution \
  -scheme LandinhoCore-Package \
  -destination 'platform=iOS Simulator,id=B741BA8C-47CD-4105-A6E6-98ADF0946FEF' \
  -derivedDataPath /tmp/landinho-about-developer-derived \
  -clonedSourcePackagesDirPath /tmp/landinho-about-developer-derived/SourcePackages \
  -jobs 2 -parallel-testing-enabled NO \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO \
  'OTHER_SWIFT_FLAGS=$(inherited) -j2' test
```

The existing UI and native scheduling captures remain from the labeled earlier
runs. This integration changes the changelog and mock test/configuration; reminder
UI and scheduling behavior are unchanged. No OS permission/delivery run was
repeated for the integration.

## Behavior limits

Reminders are local to this device and scheduled at a specific session's start.
UTC triggers preserve the instant through timezone changes. Permission is only
requested for an explicit opt-in, never on launch or schedule refresh. Cancelled,
pending-time, and started sessions cannot be newly scheduled. The app reserves
space below the platform's pending-request capacity instead of evicting reminders.

Refresh reconciles only rounds actually supplied to the app. An omitted
round/session is not an explicit cancellation. The upcoming-round endpoint filters
cancelled rounds, so Home cannot discover every round cancellation; a refreshed
round detail can supply that explicit state. There is no background server-change
tracking, push infrastructure, or guarantee that unrefreshed schedule changes will
update a previously scheduled reminder. Notification delivery remains subject to
the person's device notification settings.
