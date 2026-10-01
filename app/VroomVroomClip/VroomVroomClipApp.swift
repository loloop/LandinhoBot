import AppClipFeature
import SwiftUI

@main
struct VroomVroomClipApp: App {
  @StateObject private var model = ClipModel()

  var body: some Scene {
    WindowGroup {
      ClipView(model: model)
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
          model.receive(activity)
        }
    }
  }
}
