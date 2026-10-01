# Widget session expiry evidence

These are actual iPhone 18 Pro / iOS 27.0 simulator screenshots of the production
small and medium SwiftUI widget views in a temporary native preview harness.
They demonstrate rendering with fixed data; they are not SpringBoard-hosted
widgets and do not measure WidgetKit's scheduling latency.

- `before-upcoming.jpg`: views from base commit `14f47b9`, reference 13:00.
  The 10:00 practice is still visible, including as the small widget's next session.
- `after-upcoming.jpg`: the same fixture/reference using this branch. Practice is
  gone; qualifying at 14:00 and the race at 17:00 remain. The small view selects qualifying.
- `after-completed.jpg`: reference 17:00. Both sizes explain that no upcoming
  session remains rather than displaying past starts or claiming pending times.

Session start times are the available boundary: starts at or before an entry's
reference date disappear. Unknown times remain explicit, cancellations are
excluded from upcoming sessions, and shared calendar images retain the complete
schedule. The provider supplies entries at each future start and requests a
fresh calendar after 15 minutes; WidgetKit decides when that request runs.

## Reproduce

Create and boot your own simulator, then pass its exact UDID:

```sh
docs/evidence/widget-session-expiry/capture.sh SIMULATOR_UDID before upcoming
docs/evidence/widget-session-expiry/capture.sh SIMULATOR_UDID after upcoming
docs/evidence/widget-session-expiry/capture.sh SIMULATOR_UDID after completed
```

The script builds Foundation and WidgetUI directly with `swiftc`, installs the
preview app in that simulator, and captures/compresses the screenshots. It needs
Xcode at `/Applications/Xcode.app` and an arm64 iOS simulator. Other manual
preview scenarios are `large`, `large-completed`, `pending`, `cancelled`,
`qualifying`, and `filters`.

## Validation

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --package-path app/LandinhoFoundation
```

Nine tests passed: boundaries, every transition, simultaneous starts, pending
times, cancelled sessions/rounds, independent practice filters, empty states and
separate rounds.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -jobs 4 -skipMacroValidation -project app/VroomVroom.xcodeproj \
  -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=C1843E4C-6CA6-449B-B20B-76B2EC1E1440' \
  -derivedDataPath /tmp/landinho-widget-session-derived \
  CODE_SIGNING_ALLOWED=NO ONLY_ACTIVE_ARCH=YES build
```

The app and widget extension build passed. Apple documents the role of future
entries and system-controlled refresh in [Keeping a widget up to date](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).
