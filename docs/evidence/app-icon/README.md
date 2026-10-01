# App icon

The new VroomVroom app icon is original artwork generated with the built-in imagegen tool on 2026-10-01, without a reference image. The user explicitly requested a new icon and waived the older TODO's human-drawn requirement. The electric-lime circuit mark suggests two V turns and finishes with a checkered accent. It does not use a category or team logo.

## Bundled assets

| Consumer | Asset | Pixels |
| --- | --- | --- |
| iOS/iPadOS app icon | `app/VroomVroom/Assets.xcassets/AppIcon.appiconset/vroomvroom-icon.png` | 1024 × 1024 |
| Beta welcome/changelog | `app/LandinhoLib/Sources/BetaSheet/Assets.xcassets/AppIcon.imageset/vroomvroom-icon.png` | 1024 × 1024 |
| Sharing watermark | `app/LandinhoLib/Sources/Sharing/Assets.xcassets/AppIcon.imageset/vroomvroom-icon.png` | 128 × 128 |

The generated opaque 1254 × 1254 PNG was resized with macOS `sips`. All bundled copies remain opaque RGB PNGs. The app icon has full-bleed square corners; iOS applies the Home Screen mask. The existing SwiftUI corner masks still apply to the in-app images. The watermark copy supports its 30-point display at up to 3× resolution.

The universal 1024-pixel asset uses the app's existing asset-catalog configuration. Apple documents this approach in [Configuring your app icon using an asset catalog](https://developer.apple.com/documentation/xcode/configuring-your-app-icon) and describes system masking in [App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons).

## Generation prompt

```text
Use case: logo-brand
Asset type: final iOS app icon for VroomVroom, a motorsport calendar app
Primary request: create an original, striking motorsport icon with no reference image.
Scene/backdrop: square, full-bleed opaque deep graphite background.
Subject: one bold electric-lime abstract circuit mark that suggests two interlocking V turns and forward motion; the lime route bends smoothly like a racetrack, with a small precisely drawn cream-and-graphite checkered finish-line accent integrated into its upper right turn.
Style/medium: refined flat graphic design with crisp clean edges and a very subtle tactile finish, designed to read immediately at 30 pixels.
Composition/framing: a single centered sculptural symbol, generous graphite breathing room, symmetrical visual weight with a slight forward lean. Large enough to be recognizable in a small app icon.
Color palette: deep graphite #161B19, electric lime #D7F25B, a small warm cream accent.
Constraints: exactly square 1024 by 1024 pixels, entirely opaque, background fills every pixel through the corners. No rounded container or baked-in corner mask, no letters, no text, no border, no gradients, no drop shadows, no tiny illustration, no vehicle, no existing racing or team logos, no watermark. This is the app icon artwork itself, not a presentation mockup.
```

## Evidence

All screenshots are actual iPhone 17 simulator renders on iOS 27.0, captured with `simctl io E9AFF1D8-B586-4C58-B0CE-8C94EAC7C084 screenshot` and encoded as JPEG quality 85 for review.

| Screen | Before | After |
| --- | --- | --- |
| Home Screen | [before-home-screen.jpg](before-home-screen.jpg) | [after-home-screen.jpg](after-home-screen.jpg) |
| Beta welcome | [before-beta.jpg](before-beta.jpg) | [after-beta.jpg](after-beta.jpg) |
| Sharing watermark | [before-sharing.jpg](before-sharing.jpg) | [after-sharing.jpg](after-sharing.jpg) |

[after-sharing-dark.jpg](after-sharing-dark.jpg) also verifies the new watermark in dark appearance.

The Home Screen and beta welcome captures use normal app runs. The before app is a previously built shipping app with the unchanged old icon. The after app is the final shipping build of this branch. A local read-only fixture API supplied calendar data behind the beta sheet; no production mutation was performed.

Native UI interaction was disabled in this environment. For the sharing captures, [PreviewHarness.swift](PreviewHarness.swift) temporarily replaced the app entry point and launched the real `SharingView` with fixed sample sessions. The before and after sharing builds used the same source and data, changing only the old versus new watermark asset. This checks the rendered watermark rather than navigation into sharing. The harness remains here as a reproducible review tool and is not included in the shipping app.

The original app entry point and new assets were restored before the final app and embedded Widgets extension build, which passed with Xcode 27.1. The three compiled asset catalogs and the Widgets executable were checked in the app bundle. PNG metadata checks confirm the 1024/1024/128 pixel dimensions and absence of alpha. `git diff --check` passed. No additional unit tests were added for this asset-only change.

The final build command was:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -jobs 2 -skipMacroValidation -project app/VroomVroom.xcodeproj \
  -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=E9AFF1D8-B586-4C58-B0CE-8C94EAC7C084' \
  -derivedDataPath /tmp/landinho-admin-access-derived \
  -clonedSourcePackagesDirPath /tmp/landinho-admin-source-packages \
  CODE_SIGNING_ALLOWED=NO ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  'OTHER_SWIFT_FLAGS=$(inherited) -j2' build
```

The exact simulator was shut down after the captures.
