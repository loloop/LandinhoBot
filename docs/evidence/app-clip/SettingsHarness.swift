// Evidence-only replacement for VroomVroomApp.swift. Shows production RootView
// and Settings. Share mode presents UIKit's sheet with the identical AppSharing
// payload without claiming an automated ShareLink tap.
import ComposableArchitecture
import Foundation
import LandinhoFoundation
import SwiftUI
import UIKit

@main
struct VroomVroomApp: App {
  let store: StoreOf<Root>
  @State private var isSharing = false
  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate
  private let showShare = ProcessInfo.processInfo.environment["LANDINHO_SETTINGS_EVIDENCE"] == "share"

  init() {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "x"
    UserDefaults.standard.set(true, forKey: "me.mauriciocardozo.racing.vroomvroom.betasheet-v\(version)")
    store = Store(initialState: Root.State()) { Root() }
    store.send(.openURL(URL(string: "vroomvroom://settings")!))
  }

  var body: some Scene {
    WindowGroup {
      RootView(store: store)
        .sheet(isPresented: $isSharing) { NativeAppShareSheet() }
        .task {
          if showShare {
            try? await Task.sleep(for: .seconds(3))
            isSharing = true
          }
        }
    }
  }
}

private struct NativeAppShareSheet: UIViewControllerRepresentable {
  func makeUIViewController(context: Context) -> UIActivityViewController {
    UIActivityViewController(activityItems: [AppSharing(bundle: .main).shareText], applicationActivities: nil)
  }
  func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
