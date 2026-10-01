# iPad extra-large schedule widget evidence

These are actual native SwiftUI captures on the task-owned **iPad Pro 13-inch
(M4), iOS 27.0** simulator `39C71B10-965F-4F33-B2DB-F8739C45C5A8`. JPEG compression
preserves the captured layout. The simulator was shut down after capture and is
available for the team's next iPad validation.

The temporary app compiles the production `WidgetUI` and `CategoryUI` sources.
`capture.sh` extracts the production `NextRaceWidgetView` family switch; because
WidgetKit's `widgetFamily` environment value is read-only outside WidgetKit
hosting, only its declaration becomes an explicitly supplied family. The switch,
views, session selection and category accent are production code. This proves
native rendering and family dispatch, **not SpringBoard widget placement, gallery
interaction, or OS-delivered timeline execution**. Native interaction tools were
disabled in this environment. No production API requests were made.

`before-standard.jpg` uses the actual switch at `4ff8bc0`, where extra-large
renders `EmptyView` and is absent from `supportedFamilies`. It is an unsupported
family comparison, not a previous working extra-large widget.

| Capture | Verified behavior |
| --- | --- |
| `after-standard.jpg` | Next session and remaining sessions for one round; local zone, source and update time |
| `after-dense.jpg` | Chronological columns, six remaining sessions visible and exact overflow count |
| `after-pending.jpg` | Unknown time remains explicit; expired practice and cancelled session are absent |
| `after-filtered.jpg` | Main sessions only selects Sprint, then Corrida |
| `after-cancelled.jpg` | Explicit round cancellation has no next session |
| `after-completed.jpg` | No upcoming session after all starts have passed |
| `after-wide.jpg` | Larger 800 × 385-point footprint |
| `after-long-titles.jpg` | Long round/session titles at normal text size |
| `after-large-text-dark.jpg`, `after-large-text-max.jpg` | Dark Mode with requested accessibility sizes 1 and 5 |
| `after-long-titles-large-text.jpg` | Long titles and maximum requested Dynamic Type together |

The usual harness footprint is 720 × 342 points with 16-point content margins.
Requested accessibility sizes reduce capacity to two rows per column. The visual
font scale is capped at **xxxLarge** because this fixed widget cannot scroll;
the original uncapped accessibility-5 overflow is retained in
`before-accessibility-max-overflow.jpg`. The final maximum-size capture keeps the
next time and footer visible. Long titles may ellipsize; the combined VoiceOver
text retains their full strings. Typography bounds affect this extra-large view
only. Small/medium/large widget views and fixed sharing-image dimensions are
unchanged by this PR.

Apple documents [extra-large widget availability](https://developer.apple.com/documentation/widgetkit/widgetfamily/systemextralarge)
and [family registration and dispatch](https://developer.apple.com/documentation/widgetkit/supporting-additional-widget-sizes).

## Validation

- Four XCTest selection/layout cases passed: chronological ordering without
  duplicating the next session, balanced bounded columns and overflow accounting,
  expired/cancelled/main-session filtering with pending times, and empty/single
  session rounds. `test-schedule.sh` runs the production presentation model and
  the same test source through a dependency-free native XCTest module slice.
- The final shipping **VroomVroom** simulator build passed after rebasing onto
  App Clip commit `73ff27b`, including **WidgetsExtension** and **VroomVroomClip**.
  Both `PlugIns/WidgetsExtension.appex` and `AppClips/VroomVroomClip.app` exist in
  the built app product. No app entry was changed for evidence.
- Xcode 27.1 used the app-pinned package graph and existing DerivedData at
  `/tmp/landinho-about-developer-derived`, with Xcode build jobs set to two. The
  build log is `/tmp/landinho-extra-large-shipping-build.log`; `build-summary.txt`
  records the command and result. Existing compiler/deprecation warnings remain.
- Script syntax and `git diff --check` pass. Only the extra-large iPad TODO is
  removed from BetaSheet.

Reproduce only while holding the team's build/simulator lease, with the exact
initialized iPad UDID:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl boot 39C71B10-965F-4F33-B2DB-F8739C45C5A8

docs/evidence/extra-large-widget/capture.sh \
  39C71B10-965F-4F33-B2DB-F8739C45C5A8 before standard
docs/evidence/extra-large-widget/capture.sh \
  39C71B10-965F-4F33-B2DB-F8739C45C5A8 after standard
REUSE_EVIDENCE_BUILD=1 docs/evidence/extra-large-widget/capture.sh \
  39C71B10-965F-4F33-B2DB-F8739C45C5A8 after pending

docs/evidence/extra-large-widget/test-schedule.sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun simctl shutdown 39C71B10-965F-4F33-B2DB-F8739C45C5A8
```

Use the reuse flag only for additional scenarios after compiling the harness for
the current source revision. Omit it whenever source changes.
