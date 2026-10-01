# Mock target integration preparation

This is a static preparation record, not a passing native validation claim.
The original validated checkpoint is `723c937`, with four Siri commits above
`33341cf9a37f9f12d8da7d3600e77aa156929325`. Do not transplant main or rebase until
the final Notifications integration tip is supplied by the task coordinator.

The current main app entry injects `MockAPIClientService.liveValue` into only
the Root Store when `MOCK_NETWORKING` is defined. App Intent `perform()` and
category entity queries are separate entry points. `SiriScheduleEnvironment`
therefore sets `apiRequester` to that same mock service at both Siri query
boundaries. The production compilation branch preserves its normal injected
requester and live read-only API configuration. The Swift package does not
depend on the mock module; only the Mock app target imports it.

After the parent integration, add these two build-file entries for the existing
shared source/resource references in `app/VroomVroom.xcodeproj/project.pbxproj`:

| Mock membership | New build-file ID | Existing file reference |
| --- | --- | --- |
| `SiriSchedule.swift in Sources` | `C01100012CA0000000000005` | `C01100012CA0000000000002` |
| `AppShortcuts.xcstrings in Resources` | `C01100012CA0000000000006` | `C01100012CA0000000000004` |

Main's Mock sources phase is `17539399FBD24516B75F8A6A`; its resources phase is
`A1696A9D92F047189E20AD2C`. Append the respective new build-file IDs there.
Keep the production memberships, Portuguese development localization, both
targets' ordinary app entry, and the shipping Widget/App Clip packaging intact.
The Mock target already links `MockAPIClient` and defines `MOCK_NETWORKING`
for Debug and Release. Inspect the integrated target before applying these IDs
in case the parent merge has already added either membership.

With the sole native build/simulator lease, validate after integration:

1. Back up the integrated ordinary app entry. Temporarily use the current
   `PreviewHarness.swift`, build the `VroomVroomMock` scheme and regenerate the
   shortcut catalog training assets. This harness constructs no Root Store in
   query modes.
2. Check that localhost port 1 has no listener. Run `capture.sh` against
   `VroomVroomMock.app` for `mock` and `mock-session`. Those modes deliberately
   set `LANDINHO_API_URL=http://127.0.0.1:1`, resolve F1 through the actual
   entity query, and call both production intent entry points independently.
   Any live fallback would fail to connect. `verify-result.py` requires demo
   Formula 1 race/practice replies, the F1 tag, the mock compilation mode and
   that exact unreachable override in the app's actual result JSON.
3. Restore the integrated ordinary entry. Build both the ordinary app and
   `VroomVroomMock`, refreshing the catalog for each build. Run the metadata
   verifier for the ordinary app and with `--mock` for the Mock bundle. Require
   distinct action identifiers, the race default, both optional category
   inputs, all five Portuguese phrases and `pt-BR` SSU training. The shipping
   gate also requires its embedded Widget and App Clip; Mock packaging is
   reported as built rather than assumed to embed either extension.
4. Review the final main diff and dated pt-BR changelog, record actual results
   in the evidence README, then publish the Siri PR against main when the
   coordinator confirms the integration is ready.

Do not replace the original seven passing query JSON files or ten captures.
They remain valid direct-native evidence for the original shipping query;
append the Mock execution and integrated build records separately. Spoken Siri,
saved Shortcuts execution and tapping ShortcutsLink remain unverified.
