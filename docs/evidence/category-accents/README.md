# Category accents

These are actual iPhone 17 / iOS 27.0 simulator screenshots of the production
SwiftUI views in a temporary native harness. The harness supplies fixed rounds,
category colors and favorite state without calling the API. The widget captures
show the production widget views inside this harness, rather than SpringBoard
hosting. The sharing capture shows the real `SharingView` preview; it is not an
export or a system share-sheet capture.

`before-*` uses the prior production rendering sources from `e27f100`, which
already includes category color storage, Home favorites and round links.
`after-*` uses this change with identical fixtures. The final deep-links base
`79d3f92` adds tests and evidence to `e27f100` without changing those views.
`capture.sh` restores every substituted source before exiting. The shipping app
entry was restored and the app plus widget extension were built successfully
after both capture runs.

The deliberately challenging fixture colors are white `#FFFFFF` (Formula 1),
black `#000000` (Stock Car Brasil), yellow `#FFFF00` (Formula E), and red
`#E34B43` (IndyCar). Formula 1, Stock Car Brasil and IndyCar are favorites;
Formula E's heart is outlined. The session dates and update time are fixed.

| Surface | Before | After |
| --- | --- | --- |
| Medium schedule cards, light | [Screenshot](before-schedule-light.jpg) | [Screenshot](after-schedule-light.jpg) |
| Medium schedule cards, dark | [Screenshot](before-schedule-dark.jpg) | [Screenshot](after-schedule-dark.jpg) |
| Favorite controls, light | [Screenshot](before-categories-light.jpg) | [Screenshot](after-categories-light.jpg) |
| Favorite controls, dark | [Screenshot](before-categories-dark.jpg) | [Screenshot](after-categories-dark.jpg) |
| Yellow category detail and actions, light | [Screenshot](before-detail-light.jpg) | [Screenshot](after-detail-light.jpg) |
| Yellow category detail and actions, dark | [Screenshot](before-detail-dark.jpg) | [Screenshot](after-detail-dark.jpg) |
| Small and large widget views, light | [Screenshot](before-widgets-light.jpg) | [Screenshot](after-widgets-light.jpg) |
| Red category sharing preview, light | [Screenshot](before-sharing-light.jpg) | [Screenshot](after-sharing-light.jpg) |

All after screenshots were visually inspected. Category names and session text
retain native foregrounds. Exact-color markers have a native foreground border
so white and black remain distinguishable from the surface. Favorite controls,
the official-source link and the detail share action use a readable variant of
the category color; the stored color and marker remain unchanged. Filled and
outlined hearts still communicate favorite state independently of color.

## Contrast behavior

`CategoryColor.readableAccent(on:)` preserves colors already at 4.5:1 against
the supplied opaque surface. Otherwise it finds a minimal mix toward black or
white, checking quantized RGB candidates so rounding cannot drop contrast below
the threshold. The calculation uses the [WCAG sRGB contrast formula](https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum.html).

The shared `CategoryUI.categoryAccent` modifier uses conservative reference
surfaces for the current native app: `#F2F2F7` in light appearance and `#2C2C2E`
in dark appearance. Its 4.5:1 target applies to those references, not to arbitrary
images, materials or future tinted fills. The exact identity marker is
decorative and is paired with a category name. This follows Apple's guidance
to [check color in both appearances](https://developer.apple.com/design/human-interface-guidelines/dark-mode)
and uses the native [tint modifier](https://developer.apple.com/documentation/swiftui/view/tint%28_%3A%29-93mfq)
for the existing borderless controls.

## Reproduce and validate

Create and boot an isolated arm64 iOS simulator, then pass its exact UDID:

```sh
docs/evidence/category-accents/capture.sh SIMULATOR_UDID before
docs/evidence/category-accents/capture.sh SIMULATOR_UDID after
```

The script defaults to `/tmp/landinho-category-colors-derived`; override
`CATEGORY_ACCENT_DERIVED_DATA` for a private cache. The baseline defaults to the
merge base with `feature/deep-links`; override `CATEGORY_ACCENT_BASE_REF` to
`e27f100` to reproduce the checked-in baseline exactly. The harness is stored
only under `docs/evidence` and is not included in the app target.

Foundation validation passed all 16 tests, including three focused tests for
known contrast values, white/black/bright colors on app surfaces, unchanged
readable colors, quantization at the threshold and retained yellow hue:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --package-path app/LandinhoFoundation
```

The final shipping app and widget extension build passed:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -jobs 2 'OTHER_SWIFT_FLAGS=$(inherited) -j2' \
  -skipMacroValidation -disableAutomaticPackageResolution -skipPackageUpdates \
  -project app/VroomVroom.xcodeproj -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=B741BA8C-47CD-4105-A6E6-98ADF0946FEF' \
  -derivedDataPath /tmp/landinho-category-colors-derived \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build
```
