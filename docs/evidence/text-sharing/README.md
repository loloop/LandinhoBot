# Round text sharing evidence

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

## Reproduce

With the shared build lease, first boot an assigned task-owned iPhone simulator.
Pass its exact UDID; this script never boots or stops devices:

```sh
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID before options feature/quick-actions
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after options
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after text
docs/evidence/text-sharing/capture.sh SIMULATOR_UDID after sheet
```

Xcode must be at `/Applications/Xcode.app`, and the simulator must be arm64.
Capture outputs are JPEG-compressed without altering their layouts. The baseline
ref must be the branch before this TODO; by default it is `feature/quick-actions`.

## Validation

The formatter previously passed 26 Foundation tests, including nine new tests
for complete schedules, timezone day boundaries, unknown times/calendar days,
invalid and leap days, cancellations, empty schedules, stable ordering, Gregorian
years and daylight saving clock changes. Native capture and the final shipping
app/widget/embedded App Clip build are pending the shared validation lease.
