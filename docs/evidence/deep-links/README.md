# Round-link validation

All images are actual iOS 27.1 simulator captures from device
`404D6E16-5BA7-46A0-852A-0A97D44DEFC0`, compressed as JPEG without changing the
layout. Schedules come from the local read-only `fixture.py` at port 18084.

## External opening and its interaction limit

`before-opening.jpg` shows the shipping app's Home before opening a link.
After terminating the app, this actual command reached iOS's confirmation:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl openurl 404D6E16-5BA7-46A0-852A-0A97D44DEFC0 'vroomvroom://rounds/4caebfb4-c669-46f1-b74e-ad391517f373'
```

`external-link-confirmation.jpg` captures “Open in VroomVroom?”. The confirmation
also appeared when the app was already running. Device Hub accessibility timed
out, and the purpose-built T3 `device_open` tool reported that agent device access
was turned off. We did not enable it or confirm the dialog. These captures prove
the registered scheme and OS handoff prompt; they **do not prove a completed
external cold/warm launch after the user presses Open**.

## Native production routing harness

`PreviewHarness.swift` temporarily replaced only `VroomVroomApp.swift` to deliver
`Root.Action.openURL` without the unavailable OS button interaction. It presents
the actual `RootView`, Root, Router and EventDetail implementations and performs
real async fixture reads. These images are rendered app UI, with a test trigger
instead of a completed external OS handoff:

- `harness-before-startup.jpg`: sends the F1 URL before Root's first appearance;
  the queued destination loads Singapura with its sessions.
- `harness-after-startup.jpg`: sends the Stock Car URL two seconds after launch;
  the running app navigates to Interlagos.
- `harness-beta-queued.jpg`: first-launch BetaSheet covers a queued round URL.
- `harness-beta-delivered.jpg`: the harness sends the normal sheet-dismissal
  action after 15 seconds, then the production queue opens the same round.
- `harness-missing-round.jpg`: a valid UUID returning 404 renders the recoverable
  “Rodada não encontrada” state and retry button.

The fixture log records the BetaSheet sequence: Home/category reads at 06:48:59,
then `GET /rounds/4caebfb4-c669-46f1-b74e-ad391517f373?` at 06:49:14 after dismissal.
Native reducer tests additionally cover duplicate links/appearance, cancellation,
retry and an unrelated round ID returned by the API.

To reproduce a harness mode, temporarily use its source as the app entry, build
for the explicit simulator and launch with:

```sh
python3 docs/evidence/deep-links/fixture.py
# In another terminal, after installing the evidence build:
SIMCTL_CHILD_LANDINHO_API_URL=http://127.0.0.1:18084 SIMCTL_CHILD_LANDINHO_LINK_EVIDENCE=beta DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl launch 404D6E16-5BA7-46A0-852A-0A97D44DEFC0 me.mauriciocardozo.racing.vroomvroom
```

Modes are `cold`, `warm`, `beta`, and `missing`. Restore the ordinary app entry
after capture. The harness is evidence source only and is not in an app target.
The final build used the restored entry, passed, and was installed before the
simulator shut down. The fixture and disposable PostgreSQL instance were stopped.

## Validation

- Foundation: 17 tests, including 4 URL parser/builder/share-text tests.
- Native LandinhoCore: 14 tests, including 5 EventDetail tests, 6 existing
  ScheduleList tests and 3 existing AdminSession tests.
- Native LandinhoLib: 7 tests, including 3 Router tests and 4 existing Settings tests.
- Backend: 29 tests against a new disposable `landinho_stack_deep_links` database
  on the task-owned PostgreSQL instance at 127.0.0.1:55435. The public round read
  includes category, pending sessions, a past cancelled round and missing-ID 404.
- Shipping app: build passed both before evidence and after restoring the entry.
- Plists, AASA JSON and `git diff --check` passed.

Native tests used the app's pinned package versions, cap 2 and the available
DerivedData/SourcePackages at `/tmp/landinho-about-developer-derived`. Temporary
package pin changes used for these runs were restored. No domain or AASA was
deployed; HTTPS association and physical-device Universal Link testing remain
the future activation steps described in `docs/deep-links/README.md`.
