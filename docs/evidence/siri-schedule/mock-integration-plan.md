# Mock target verification

The Root Store scopes its mock requester to reducer operations. App Intent
`perform()` and category entity queries are independent entry points.
`SiriScheduleEnvironment` therefore sets `apiRequester` to
`MockAPIClientService.liveValue` at both Siri query boundaries when the app target
is compiled with `MOCK_NETWORKING`. The ordinary app preserves its normal
requester and live read-only API configuration. The Core package does not depend
on the mock module; only the Mock app target imports it.

The Mock target includes the shared `SiriSchedule.swift` source and
`AppShortcuts.xcstrings` catalog. Its Debug and Release configurations already
define `MOCK_NETWORKING` and link `MockAPIClient`. The ordinary app retains its
Siri memberships and embedded Widget/App Clip packaging.

On 01/10/2026, after integrating Notifications/main at
`c5b2b5cddab8cee6b2a915f99aa8e0f8fb99ccb1`, the temporary native harness called
both real intent entry points without constructing a Root Store. Each call
resolved F1 through `RacingCategoryQuery.entities(matching:)` first. The
`LANDINHO_API_URL` override was deliberately set to `http://127.0.0.1:1`, with
no local listener. Both calls returned the in-memory demo's Formula 1 race and
practice successfully. The actual JSON records the mock compilation mode,
category tag, override and returned text in `mock-result.json` and
`mock-session-result.json`. A live fallback would have failed to connect.

The corresponding actual simulator captures are `harness-mock-light.jpg` and
`harness-mock-session-light.jpg`. They show the production snippet rendered with
the exact native result, not a Siri system screen.

To reproduce under the sole native build/simulator lease:

1. Back up the ordinary app entry; temporarily use `PreviewHarness.swift` and
   build the `VroomVroomMock` scheme. The harness creates no Root Store in query
   modes. Use an initialized task-owned simulator and check port 1 has no listener.
2. Run `capture.sh EXACT_UDID VroomVroomMock.app mock`, then `mock-session`.
   The script reads the app's actual bundle identifier, sets the unreachable
   override, calls the real intents and verifies the written JSON.
3. Restore the ordinary app entry and build both app schemes. Refresh the
   shortcut catalog training assets for incremental builds. Verify normal
   metadata with `verify-metadata.py VroomVroom.app` and Mock metadata with
   `verify-metadata.py VroomVroomMock.app --mock`.

The final build records are described in the evidence README. Discovery checks
require distinct action identifiers, the race default, optional category inputs,
all five Portuguese phrases and `pt-BR` SSU training. The ordinary app gate also
requires its embedded Widget and App Clip; Mock packaging is reported as built.
The original seven query results and ten captures remain unchanged; the Mock
records are additional native evidence. Spoken Siri, saved Shortcuts execution
and tapping ShortcutsLink remain unverified.
