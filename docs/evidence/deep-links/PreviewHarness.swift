import SwiftUI
import ComposableArchitecture
import Foundation

// Temporary local evidence harness; restored before final app build.
@main
struct VroomVroomApp: App {
  let store: StoreOf<Root>
  let mode = ProcessInfo.processInfo.environment["LANDINHO_LINK_EVIDENCE"] ?? "cold"
  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  init() {
    let mode = ProcessInfo.processInfo.environment["LANDINHO_LINK_EVIDENCE"] ?? "cold"
    let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
    let key = "me.mauriciocardozo.racing.vroomvroom.betasheet-v\(version)"
    UserDefaults.standard.set(mode != "beta", forKey: key)
    store = Store(initialState: Root.State()) { Root() }
    if mode == "cold" || mode == "beta" {
      store.send(.openURL(URL(string: "vroomvroom://rounds/4caebfb4-c669-46f1-b74e-ad391517f373")!))
    }
  }

  var body: some Scene {
    WindowGroup {
      RootView(store: store)
        .task {
          if mode == "beta" {
            try? await Task.sleep(for: .seconds(15))
            store.send(.setBetaSheet(false))
          } else if mode == "warm" || mode == "missing" {
            try? await Task.sleep(for: .seconds(2))
            let id = mode == "warm" ? "66b884bc-a00d-43e7-993c-bad5dd135c39" : "00000000-0000-0000-0000-000000000999"
            store.send(.openURL(URL(string: "vroomvroom://rounds/\(id)")!))
          }
        }
    }
  }
}
