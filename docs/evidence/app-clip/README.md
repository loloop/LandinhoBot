# App Clip and app-sharing evidence

These are actual iPhone 17 / iOS 27.0 simulator captures from the initialized,
task-owned device `E9AFF1D8-B586-4C58-B0CE-8C94EAC7C084`. Screenshots were compressed
as JPEG without changing their layout. The public GET requests use the read-only
local `fixture.py` at `http://127.0.0.1:18085`; no production mutations were made.

## What the native harness proves

`ClipHarness.swift` temporarily replaced only the entry for the **real
VroomVroomClip target**. It passes synthesized
`NSUserActivityTypeBrowsingWeb` activities to the production `ClipModel`, then
shows the production `ClipView` and performs real asynchronous public API reads.
It does not mock any view, route parser, calendar client or session model.

| Capture | Exercised behavior |
| --- | --- |
| `clip-cold.jpg` | F1 category invocation before the first view appears |
| `clip-categories.jpg` | Public categories list |
| `clip-round.jpg` | Round sessions, with confirmed and pending times using consistent month-name dates |
| `clip-restored.jpg` | A new process launched without a URL restores the previously viewed round |
| `clip-invalid.jpg` | Foreign URL shows recovery and upcoming rounds |
| `clip-missing.jpg` | Public round GET returns 404 and shows retry/recovery |
| `clip-settings.jpg` | Settings route offers full-app handoff while showing public upcoming rounds |
| `clip-warm-before.jpg`, `clip-warm-after.jpg` | A new invocation replaces F1 with the Stock Car round while the process is running |
| `clip-handoff-native.jpg` | The production handoff method calls UIKit for `vroomvroom://settings`; with the full app absent, UIKit returns `accepted=false` and the production alert appears |
| `clip-handoff.jpg` | The same fallback alert, using an explicitly deterministic rejected-opener test result |

`native-handoff.txt` records the **actual** requested URL and the UIKit completion
at 07:38:58. No successful external handoff is claimed. The earlier 7-second
handoff screenshot was replaced after checking the real completion and allowing
15 seconds for rendering.

The invocation activities are local harness inputs, **not OS-delivered production
App Clip invocations**. Native interaction tools were disabled in this
environment, so no App Clip card, physical-device QR/NFC invocation, successful
installed-full-app handoff, or public Universal Link activation was tested. The
shared Xcode scheme includes Apple's `_XCAppClipURL` debug variable. Signing is
disabled for these simulator builds; signed-device lifecycle/distribution checks
remain part of the activation instructions in `docs/app-clip/README.md`.

## Settings and sharing

`SettingsHarness.swift` temporarily replaced only the full app entry. It sends
`Root.Action.openURL(vroomvroom://settings)` into the production Root/Router and
shows the actual Settings view:

- `app-settings.jpg` shows **Compartilhar o app**, its beta fallback explanation,
  and the existing about/admin-version entry.
- `app-share.jpg` shows a native UIKit activity sheet with the **identical
  `AppSharing(bundle: .main).shareText` payload used by the production ShareLink**.
  The harness presents that controller directly; it does not claim a simulated
  tap on ShareLink. The payload contains the explicitly labeled installed-app
  link and the working VroomVroom project page, not the undeployed canonical host.

The before comparison reuses the real prior Settings capture at
`../admin-access/after-settings.jpg`, recorded before the share row existed.
This avoids a redundant baseline build and is not a recreated screenshot.

## Build, tests and size

- **17 Clip tests pass**: invocation routing/restoration, warm/repeated/invalid
  links, settings handoff, stale destination/reload responses, public API
  contracts, pending-time decoding, 404/retry, unrelated round ID rejection,
  accepted/rejected full-app opening, and localized/source-day date semantics.
- **23 Foundation tests pass**, including **3 AppSharing tests** for the beta
  fallback, configured Clip priority, App Store fallback and malformed links.
- The Clip's native simulator build passes. After restoring both shipping
  entries, the final **VroomVroom build passes**, including **WidgetsExtension**
  and **VroomVroomClip**. The actual full app product contains
  `AppClips/VroomVroomClip.app` and `PlugIns/WidgetsExtension.appex`.
- The native **Release / iphoneos / arm64** Clip build passes with shipping
  sources. Its unsigned, unthinned bundle is **2,671,985 bytes (2.672 MB)**;
  executable **858,768 bytes**. This is below the conservative **15 MB** budget.
  `release-size.json` records the exact file-size sum. This is a preliminary
  device-build measurement, **not a signed App Thinning distribution size
  report**. Signed archive/export size remains a release check.
- Source entitlements, actual built Clip Info.plist, matching parent/Clip IDs,
  versions/team/device families, embedding/dependency, prepared AASA, shell/Python
  syntax, and `git diff --check` pass. The Clip requests neither notifications
  nor location and has no configured dead production distribution keys.

The final builds used Xcode 27.1 with concurrency cap 2 and the existing
app-pinned DerivedData at `/tmp/landinho-about-developer-derived`. The entries
were restored, the final shipping app installed, the fixture stopped, and the
task-owned simulator shut down before releasing the build lease.

Reproduce only while holding the team's build/simulator lease:

```sh
LANDINHO_EVIDENCE_SIMULATOR=E9AFF1D8-B586-4C58-B0CE-8C94EAC7C084 \
LANDINHO_EVIDENCE_DERIVED=/tmp/landinho-about-developer-derived \
  docs/evidence/app-clip/capture.sh
```

The script uses the existing initialized device, restores source entries on exit,
and stops only its own fixture/device. It does not deploy a website/AASA, publish
the app, configure App Store Connect, or enable production links.
