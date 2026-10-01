# VroomVroom App Clip

`VroomVroomClip` is an iOS 17+ App Clip target embedded by the full app's **Embed
App Clips** phase. Its identifier is
`me.mauriciocardozo.racing.vroomvroom.Clip`; its parent is
`me.mauriciocardozo.racing.vroomvroom`, signed by team `UQCQ667RNK`.

The Clip links only `AppClipFeature` and `LandinhoFoundation`. It uses the shared
`AppRoute`, category/round/session models and session time labels. It calls the
existing public `GET /category`, `GET /next-races?page=1&per=5&category=<tag>` and
`GET /rounds/<UUID>` endpoints through an ephemeral URLSession. It includes no
administration, favorites store, widgets or third-party packages. The preview
shows five upcoming rounds; a round view shows all its sessions, including
pending times and cancellations. Clip dates use consistent localized month
names; confirmed instants use the device timezone while source-only days retain
their calendar date. `LANDINHO_API_URL` supports HTTPS overrides or
an HTTP loopback fixture server for development.

## Invocation and handoff

The SwiftUI `onContinueUserActivity(NSUserActivityTypeBrowsingWeb)` handler feeds
invocation URLs to the shared parser. `/home`, `/categories`, `/categories/<tag>`
and `/rounds/<UUID>` show public calendars. `/settings` shows the upcoming rounds
and explains that settings belong to the full app; the handoff retains the
settings destination. New invocations replace the current destination and cancel
old view tasks; late API results cannot overwrite newer destinations or reloads.

Without an invocation URL, the Clip restores its last destination from its own
UserDefaults. Invalid or foreign URLs show a recovery message and the upcoming
rounds. A missing round has a retry and a route back to upcoming rounds. URLs do
not choose the API host or authorize requests.

**Abrir app instalado** uses the registered `vroomvroom://` route, preserving the
current category, round or settings destination. If the app is unavailable, the
Clip explains that the calendar remains usable here. Installation promotion via
`SKOverlay.AppClipConfiguration` is shown only when a released App Store URL has
been explicitly configured.

## Sharing while the app is in beta

Settings has **Compartilhar o app**, backed by the native ShareLink sheet. No
verified App Store or TestFlight link exists in this repository. Its current
payload contains an explicitly labeled link for an installed app and the working
[project page](https://github.com/loloop/LandinhoBot). It does not share the
reserved, currently undeployed `vroomvroom.racing` website.

After verifying production availability, add one or both Info.plist keys to the
full app and Clip:

- `VroomVroomAppClipURL`: a verified HTTPS URL matching an `AppRoute` on the
  canonical host, such as `/home` or `/categories/f1`. This takes share priority.
- `VroomVroomAppStoreURL`: the verified `https://apps.apple.com/.../id<digits>`
  product URL. This enables installation promotion in the Clip and is the share
  destination when no Clip URL is configured.

Malformed values are ignored. These values are explicit release configuration;
the code cannot determine whether a configured experience is published. Leave
them absent until the corresponding live link has been checked. Apple-generated
default/demo Clip links are not supported by `AppRoute`; use a verified custom
experience with a supported route for this version.

## Local testing

Select the shared **VroomVroomClip** scheme. Its Run action includes Apple's
`_XCAppClipURL=https://vroomvroom.racing/categories/f1` debug invocation. This is a
local debugger fixture, not a published App Clip link. Change it to a round URL,
`/settings`, a malformed URL, or disable it to verify restoration/no-URL launch.
Debug invocations launch the executable without presenting the system App Clip
card. Use a local experience on a physical iPhone to verify the card and QR/NFC
launch; Apple's local QR/NFC testing does not require deployed associated domains.

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --package-path app/LandinhoClip --jobs 2
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  swift test --package-path app/LandinhoFoundation --jobs 2
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcodebuild -jobs 2 -skipMacroValidation -project app/VroomVroom.xcodeproj \
  -scheme VroomVroom -destination 'platform=iOS Simulator,id=<owned-simulator-UDID>' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES 'OTHER_SWIFT_FLAGS=$(inherited) -j2' \
  CODE_SIGNING_ALLOWED=NO build
```

Building the full app also builds and embeds the Clip. To run only the Clip, use
`-scheme VroomVroomClip`. Tests cover cold/warm/repeated/invalid/no-URL invocations,
settings handoff, restoration, stale responses, public endpoint/query contracts,
404/retry, ISO-8601/pending session decoding, and sharing configuration.

## Production activation remains external

This change does not deploy a domain, publish an App Store version, create an App
Store Connect experience, or activate production Universal Links. Before release:

1. Enable the App Clip capability for the parent/Clip signing identifiers and
   verify a signed device/archive build. Xcode synthesizes the parent's
   `associated-appclip-app-identifiers` entitlement when archiving the embedded
   Clip; the Clip's source entitlement names the parent using `AppIdentifierPrefix`.
   Deploy the backend version containing the public `GET /rounds/<UUID>` route
   from the deep-links layer before enabling live round invocations.
2. Deploy HTTPS pages and the AASA from `docs/deep-links/apple-app-site-association`
   on the owned canonical domain. Add `applinks:vroomvroom.racing` to the full
   app and `appclips:vroomvroom.racing` to the Clip's signed entitlements (examples
   below). Keep these capabilities absent until the domain is operational.
3. Upload the full app and embedded Clip together. Configure the default App Clip
   experience and any advanced experiences in App Store Connect with supported
   URLs. Prefer `/home` as the generic invocation rather than the unsupported
   domain root. The full app already handles the same routes through `onOpenURL`.
4. Verify App Clip card/launch on a physical iPhone, TestFlight experiences and
   installed-full-app Universal Link invocation. Set the sharing keys only after
   release and link verification.
5. Export the signed Release archive with App Thinning and inspect **App Thinning
   Size Report.txt** for every variant. Apple's ordinary iOS 16 limit is 15 MB;
   iOS 17+ permits 100 MB only for eligible digital experiences or the demo link.
   This Clip intentionally targets under 15 MB so it need not rely on the larger
   allowance. Unsigned simulator/device bundle measurements are preliminary,
   not a distribution size certification.

References: [Creating an App Clip](https://developer.apple.com/documentation/appclip/creating-an-app-clip-with-xcode),
[responding to invocations](https://developer.apple.com/documentation/appclip/responding-to-invocations),
[testing the launch experience](https://developer.apple.com/documentation/appclip/testing-the-launch-experience-of-your-app-clip),
[size limits and available APIs](https://developer.apple.com/documentation/appclip/choosing-the-right-functionality-for-your-app-clip),
[StoreKit overlay](https://developer.apple.com/documentation/storekit/skoverlay).
