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
        .task {
          if showShare {
            try? await Task.sleep(for: .seconds(3))
            guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let controller = scene.windows.first(where: \.isKeyWindow)?.rootViewController
            else { return }
            let sheet = UIActivityViewController(activityItems: [AppSharing(bundle: .main).shareText], applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = controller.view
            sheet.popoverPresentationController?.sourceRect = controller.view.bounds
            controller.present(sheet, animated: true)
          }
        }
    }
  }
}
