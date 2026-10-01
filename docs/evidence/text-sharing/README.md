# Round text sharing evidence

All seven images are actual iPhone 17 / iOS 27.0 simulator screenshots from
`B741BA8C-47CD-4105-A6E6-98ADF0946FEF`, compressed as JPEG without changing their
layouts. The simulator is a task-owned device, reused with the shared build lease.

`PreviewHarness.swift` is a standalone native evidence app, outside all shipping
targets. `capture.sh` compiles the production Foundation sources and
`RoundShareMenu.swift` directly with `swiftc -j2`; it does not alter the ordinary
app entry or add a product flow.

The `options` scenario renders the exact production `RoundShareActions` views in
a native SwiftUI List. The baseline extracts the existing link/image action
content from EventDetail and substitutes only the image delegate closure. This
lets before/after evidence show the available actions without native taps. These
are **action-content previews, not captures of an expanded context menu**.

The `text` scenario displays the production formatter's actual plain String. The
fixed fixture contains a timed practice, a pending qualifying time with a known
calendar day, a cancelled sprint and a timed race. It retains the full schedule.
The harness process uses `America/Sao_Paulo` and Portuguese locale.

The `sheet` scenario presents `UIActivityViewController(activityItems: [text])`
with the same actual String. It proves the native system share sheet accepts the
payload; it does not prove a tap on the production ShareLink or delivery into a
destination app. No share destination is selected and no message is sent.
The shipping detail toolbar uses `ShareLink(item: String)` through
`RoundShareMenu`; the image navigation closure and link item are preserved.

Native interaction is unavailable in this environment: T3 device access is
disabled and Device Hub accessibility times out. No interaction bypass is used.

## Captures

- `before-options.jpg`: native action-content preview from quick-actions base
  `d60f77a`, offering link and image sharing.
- `after-options.jpg`: production action views now also offer text sharing.
- `after-text.jpg`: full round text with category, title, bot-style emojis, full
  dates, explicit device timezone, a pending qualifying time and cancelled sprint.
- `after-sheet.jpg`: actual native system share sheet presenting that String.
- `after-pending.jpg`: a known scheduled day and an unknown day retain explicit
  pending labels; no midnight substitute is displayed.
- `after-cancelled.jpg`: cancellation of the round applies to every session,
  suppressing old start times and the pending-time advisory.
- `after-empty.jpg`: an empty round reports pending times without inventing a date.

## Reproduce

With the shared build lease, first boot an assigned task-owned iPhone simulator.
Pass its exact UDID; this script never boots or stops devices:

```sh
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID before options feature/quick-actions
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after options
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after text
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after sheet
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after pending
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after cancelled
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after empty
```

Xcode must be at `/Applications/Xcode.app`, and the simulator must be arm64.
Capture outputs are JPEG-compressed without altering their layouts. The baseline
ref must be the branch before this TODO; by default it is `feature/quick-actions`.

## Validation

The rebased branch passed all 34 Foundation tests, including nine new tests
for complete schedules, timezone day boundaries, unknown times/calendar days,
invalid and leap days, cancellations, empty schedules, stable ordering, Gregorian
years and daylight saving clock changes:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test \
  --package-path app/LandinhoFoundation \
  --scratch-path /tmp/landinho-text-sharing-foundation-tests --jobs 2
```

The final shipping app/widget/embedded App Clip build is pending.
