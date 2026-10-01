# Opening and sharing rounds

The app registers `vroomvroom` and receives URLs through SwiftUI `onOpenURL` on
`RootView`. The same callback handles future Universal Links. Incoming URLs are
parsed by `LandinhoFoundation.AppRoute`; they never choose the API host or trigger
a fetch from their own URL. Round detail reads use the configured API's public
`GET /rounds/:id` endpoint, including the category and all sessions. Past and
cancelled rounds remain addressable; missing rounds return 404 and malformed IDs 400.

| Destination | Working URL with app installed | Future HTTPS URL |
| --- | --- | --- |
| Home | `vroomvroom://home` | `https://vroomvroom.racing/home` |
| Categories | `vroomvroom://categories` | `https://vroomvroom.racing/categories` |
| Category | `vroomvroom://categories/f1` | `https://vroomvroom.racing/categories/f1` |
| Settings | `vroomvroom://settings` | `https://vroomvroom.racing/settings` |
| Round | `vroomvroom://rounds/<UUID>` | `https://vroomvroom.racing/rounds/<UUID>` |

## Shared API

```swift
if let route = AppRoute(url: incomingURL) {
  store.send(.openRoute(route)) // StoreOf<Router>
}

let roundRoute = AppRoute.round(id: round.id)
let installedAppURL = roundRoute.url
let futureWebsiteURL = roundRoute.canonicalURL
```

`AppRoute` is `Equatable`, `Hashable` and `Sendable`. Category tags are nonempty,
at most 64 UTF-8 bytes, and contain letters, numbers, `-` or `_`; their case is
preserved for backend queries. URL construction returns nil for invalid tags.
The parser rejects unknown schemes and hosts, user credentials, explicit ports,
queries, fragments, extra path segments, malformed UUIDs and double-encoded
path separators. Builders encode category tags and round-trip through the parser.

The full app sends `Root.Action.openURL(URL)` so an invocation before startup or
during the first-launch BetaSheet is retained. The most recent valid invocation
wins; closing the sheet delivers it. Repeated identical links keep a single
detail screen. Leaving detail cancels its read; loading failures support retry.
An App Clip can parse its invocation URL with the same `AppRoute` API and route
after its own launch setup. App shortcuts can send `Router.Action.openRoute`
directly with the same validation.

The detail screen's Share menu offers a round link as well as the existing image
sharing. `Race.roundLinkShareText` includes its custom URL. For F1 it also includes
the working **generic** `https://calendariof1.com/` homepage, labeled “F1 na web
(Calendário F1)”. It does not imply a specific round page. Other categories do not
get an invented web fallback. Custom schemes need an installed app and cannot
provide a browser redirect by themselves.

## Future Universal Link activation

**No website, AASA or domain association was deployed by this change.**
`vroomvroom.racing` follows the existing API domain in the codebase, but its apex
did not resolve during the 2026-10-01 check. Confirm ownership, DNS and TLS before
using it. `canonicalURL` and the files in this directory are preparation for that
deployment; the app shares the custom URL today.

1. Obtain the separate authorization needed to deploy the website. Confirm the
   app's Application Identifier Prefix and bundle ID against the provisioning
   profile; the sample uses the Xcode project's current team and app identifiers.
2. Serve `apple-app-site-association` at
   `https://vroomvroom.racing/.well-known/apple-app-site-association` with
   `application/json`, no extension and no redirect. Publish actual HTTPS pages
   matching every supported path. A round page can show its public schedule and
   link to the installed app; for F1 offer the generic Calendário F1 fallback.
   The website should use the API's fixed origin and validate the ID itself.
3. Copy `UniversalLinks.entitlements.example` to the app's entitlements file,
   merging any existing entitlements. Enable Associated Domains for the app ID
   and configure `CODE_SIGN_ENTITLEMENTS` in Debug and Release to that merged
   file. The example is intentionally absent from the build configuration now.
4. Install a newly signed build on a physical device. Open a link from Notes or
   another app, covering both terminated and running states, first-launch sheet,
   missing round, retry, repeated links and category/Home/Settings routes. Check
   the hosted AASA and the signed entitlements. Simulator custom-scheme evidence
   is not proof of deployed domain association.
5. After the hosted paths and device association work, change the sharing policy
   to HTTPS. App Clip experiences additionally require their own signed domains,
   hosted `appclips` AASA entries and App Store Connect setup; the full app must
   keep handling the same invocation routes.

Apple references: [onOpenURL](https://developer.apple.com/documentation/swiftui/view/onopenurl(perform:)),
[supporting associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains),
[App Clip invocations](https://developer.apple.com/documentation/appclip/responding-to-invocations).

## Local validation

Run dependency-free parsing and share-text tests:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer swift test --package-path app/LandinhoFoundation --jobs 2
```

`EventDetailTests` in LandinhoCore cover loading by UUID, duplicate appearance,
404 and retry, cancellation, an unrelated ID returned by the API, and preloaded
rounds. `RouterTests` in LandinhoLib cover navigation replacement, repeated links,
tab routes and invalid programmatic routes. These packages require an iOS
destination because their UI dependencies import UIKit. Use a private package
cache with the app's pinned `Package.resolved` when running package tests.
`RoundDetailTests` cover malformed IDs without a database; its public read/404
test requires `LANDINHO_TEST_DATABASE=1` and disposable PostgreSQL credentials.

For installed-app checks, use an explicit simulator UDID:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl openurl <UDID> 'vroomvroom://rounds/<UUID>'
```

Set `SIMCTL_CHILD_LANDINHO_API_URL` before `simctl launch` to use a local fixture
API for reproducible evidence. Do not send production mutation requests.
