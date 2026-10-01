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

Simulator validation and before/after screenshots will be recorded here after the serialized build slot becomes available.

