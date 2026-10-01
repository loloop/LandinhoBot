// Evidence-only entry for the real VroomVroomClip target. Replace its app entry
// temporarily; restore it before the final shipping build. No mock view is used.
import AppClipFeature
import Foundation
import SwiftUI
import UIKit

@main
struct VroomVroomClipApp: App {
  @StateObject private var model: ClipModel
  private let mode = ProcessInfo.processInfo.environment["LANDINHO_CLIP_EVIDENCE"] ?? "cold"

  init() {
    let mode = ProcessInfo.processInfo.environment["LANDINHO_CLIP_EVIDENCE"] ?? "cold"
    let suite = "VroomVroomClip.localEvidence"
    let defaults = UserDefaults(suiteName: suite)!
    if mode != "restored" { defaults.removePersistentDomain(forName: suite) }
    let model = ClipModel(defaults: defaults)
    let url: String?
    switch mode {
    case "cold", "warm": url = "https://vroomvroom.racing/categories/f1"
    case "categories": url = "https://vroomvroom.racing/categories"
    case "round": url = "https://vroomvroom.racing/rounds/4caebfb4-c669-46f1-b74e-ad391517f373"
    case "settings", "handoff": url = "https://vroomvroom.racing/settings"
    case "invalid": url = "https://evil.example/categories/f1"
    case "missing": url = "https://vroomvroom.racing/rounds/00000000-0000-0000-0000-000000000999"
    default: url = nil
    }
    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    activity.webpageURL = url.flatMap(URL.init(string:))
    model.receive(activity)
    _model = StateObject(wrappedValue: model)
  }

  var body: some Scene {
    WindowGroup {
      ClipView(model: model)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { model.receive($0) }
        .task {
          if mode == "warm" {
            try? await Task.sleep(for: .seconds(10))
            let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
            activity.webpageURL = URL(string: "https://vroomvroom.racing/rounds/66b884bc-a00d-43e7-993c-bad5dd135c39")!
            model.receive(activity)
          } else if mode == "handoff" {
            try? await Task.sleep(for: .seconds(5))
            // Same production handoff method as the button, called without an
            // unavailable UI tap. Full app is temporarily absent on this device.
            model.openFullApp { url, completion in
              UIApplication.shared.open(url, options: [:], completionHandler: completion)
            }
          }
        }
    }
  }
}
