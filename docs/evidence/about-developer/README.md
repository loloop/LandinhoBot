# About developer screen evidence

Actual simulator captures of production SwiftUI views using a temporary native preview harness. These are not mockups. Device Hub's accessibility interface timed out, so the harness opened the views directly instead of automating taps through the app's tabs.

- Device: iPhone 18 Pro, iOS 27.0.
- Simulator: `A4686CCD-3BA6-45BF-8B19-FED85DCE9563` (Landinho About Developer).
- `before-settings.png`: unchanged Settings view before replacing the placeholder button.
- `after-light.png`: developer screen in light appearance, standard Dynamic Type.
- `after-dark.png`: developer screen in dark appearance, standard Dynamic Type.
- `after-large-text.png`: developer screen at `accessibility-medium` Dynamic Type; labels wrap without truncation.

The temporary app entry point hosted `SettingsView` inside `NavigationStack`. For the after captures, a temporary wrapper in the Settings target attached:

```swift
.navigationDestination(isPresented: .constant(true)) {
  AboutDeveloperView()
}
```

The harness used the production view implementations without changing their layout or styles. It did not issue backend requests. The wrapper was deleted and the normal app entry point restored before the final build. External link taps and a VoiceOver walkthrough were not exercised through Device Hub.

Build and capture commands, from the worktree root:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -skipMacroValidation -project app/VroomVroom.xcodeproj -scheme VroomVroom \
  -destination 'platform=iOS Simulator,id=A4686CCD-3BA6-45BF-8B19-FED85DCE9563' \
  -derivedDataPath /tmp/landinho-about-developer-derived -jobs 4 \
  CODE_SIGNING_ALLOWED=NO build

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl install \
  A4686CCD-3BA6-45BF-8B19-FED85DCE9563 \
  /tmp/landinho-about-developer-derived/Build/Products/Debug-iphonesimulator/VroomVroom.app

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl launch \
  --terminate-running-process A4686CCD-3BA6-45BF-8B19-FED85DCE9563 \
  me.mauriciocardozo.racing.vroomvroom

DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun simctl io \
  A4686CCD-3BA6-45BF-8B19-FED85DCE9563 screenshot <output.png>
```

The public profile's name and username were confirmed with `gh api users/loloop`; the repository with `gh api repos/loloop/LandinhoBot`. Both displayed GitHub URLs returned HTTP 200.
