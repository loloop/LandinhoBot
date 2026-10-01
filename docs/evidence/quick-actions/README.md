# Home Screen quick-action validation

Captured on 2026-10-01 from the task-owned iPhone 17 simulator running iOS 27.0,
UDID `B741BA8C-47CD-4105-A6E6-98ADF0946FEF`. Every image is an actual simulator
screenshot, compressed as JPEG without changing its layout.

`PreviewHarness.swift` is a temporary app entry for native validation and evidence.
It is not part of an app target. `capture.sh` restores the ordinary entry and
builds the shipping app and its scheme dependencies after the harness run.

## Scope of the native trigger

The harness renders the production `RootView`, `Root`, `Router`, Home, Categories
and Settings implementations. Schedules are read from the existing local,
read-only deep-link fixture at `127.0.0.1:18084`.

The startup modes call `VroomSceneDelegate.handleQuickAction` before `RootView`
exists or binds its store. This is the same method called by
`connectionOptions.shortcutItem` during an actual cold scene connection. The
warm modes call the production `windowScene(_:performActionFor:completionHandler:)`
method with the real window scene after the production view has appeared.

These triggers exercise production routing and its scene/store deferral. They
do not press an app icon, display the Home Screen quick-action menu, or prove an
OS-driven cold/warm shortcut callback. Native device interactions are disabled
in this environment; that setting is not bypassed.

The published static actions are Próximas sessões (`calendar`), Categorias
(`square.grid.2x2`), and Ajustes (`gearshape`). Their exact identifiers are
validated against the app's `Info.plist` by Foundation tests.

## Native integration cases

The harness includes six cases using the production scene delegate and Root
store, with a reducer that records the actions that actually reach the store:

- An action received before store binding enters Root's startup queue, navigates
  after appearance, and is not replayed when SwiftUI binds the store again.
- The latest valid action before binding wins; an unknown action cannot erase it.
- All three warm actions select their existing destination, each with one
  successful completion callback.
- An unknown warm identifier calls completion once with failure and leaves the
  selected tab unchanged.
- Startup and warm actions remain behind the first-launch BetaSheet; dismissal
  delivers the latest destination once.
- Two delegate instances retain and deliver only their own store's pending action.

The cases restore the beta preference and write a JSON result into the app's
Documents directory. The capture script checks six cases and zero failures
before producing screenshots.

## Reproduction

Native execution must wait for the parent's exclusive build/simulator lease.
Use only the initialized task-owned simulator and app DerivedData approved by
the parent. The script requires the exact simulator UDID to already be booted
and does not boot or shut down any device:

```sh
bash docs/evidence/quick-actions/capture.sh APPROVED_UDID APPROVED_DERIVED_DATA_PATH
```

Verify that no other task owns fixture port 18084. Xcode runs with `-jobs 2` and
requests `-j2` through `OTHER_SWIFT_FLAGS`; this Xcode version appends a later
`-j12` for the app compiler, so that flag does not cap every nested compiler.
All modes run against one evidence build; then the unchanged app entry is
restored for a final shipping build.

## Captures

| Capture | Observed production UI |
| --- | --- |
| `before-warm-settings.jpg` / `after-warm-settings.jpg` | Home before invocation → Settings after the warm scene method accepts Ajustes. |
| `after-startup-categories.jpg` | Categories after an action received before RootView/store binding. |
| `after-startup-settings.jpg` | Settings after an action received before RootView/store binding. |
| `before-warm-home.jpg` / `after-warm-home.jpg` | A category schedule destination in its loading state, with Back visible → Home after Próximas sessões clears navigation. The first image does not show a loaded category schedule. |
| `beta-queued.jpg` / `beta-delivered.jpg` | First-launch BetaSheet covering a queued Settings action → Settings after the harness sends the ordinary sheet-dismissal action. |
| `unknown-stays-home.jpg` | Home remains selected after the warm scene method rejects an unknown identifier. |

## Results

- [Native result](native-tests.json): six production scene/Root integration cases,
  zero failures. These are executable native assertions in the temporary app
  entry, rather than XCTest cases or an OS Home Screen interaction test.
- Two quick-action Foundation tests passed within the 19-test Foundation run at
  the coding checkpoint. They validate published identifiers/destinations and
  rejection of unknown identifiers.
- The native evidence build passed. The normal app entry was restored before the
  final shipping build, which also passed after restacking onto the published
  extra-large-widget tip `910c610`.
- The final app bundle contains the app executable, embedded WidgetsExtension,
  embedded VroomVroomClip, and all three static quick-action labels, identifiers
  and SF Symbols. The final build was installed on the exact simulator above.
- Plist lint, Swift source parsing, shell syntax and `git diff --check` passed.
- The local fixture process stopped and the task simulator was shut down after
  capture. No production write request was made.

Xcode used the app-pinned dependency cache at
`/tmp/landinho-about-developer-derived/SourcePackages`. The build logs were
`/tmp/landinho-quick-actions-harness-build.log` and
`/tmp/landinho-quick-actions-shipping-build.log`. The final build retained the
existing TCA scoping deprecation warnings and the no-AppIntents metadata notice;
it had no build errors.

## Apple references

- [Add Home Screen quick actions](https://developer.apple.com/documentation/uikit/add-home-screen-quick-actions)
  documents static SF Symbol icons, cold `connectionOptions.shortcutItem` and the
  warm scene callback.
- [windowScene(_:performActionFor:completionHandler:)](https://developer.apple.com/documentation/uikit/uiwindowscenedelegate/windowscene(_:performactionfor:completionhandler:))
  documents completing the callback with the action's success or failure.
