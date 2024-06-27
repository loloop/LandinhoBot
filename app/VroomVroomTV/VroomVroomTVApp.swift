//
//  VroomVroomTVApp.swift
//  VroomVroomTV
//
//  Created by Mauricio Cardozo on 20/05/24.
//

import ComposableArchitecture
import SwiftUI
@_spi(Internal) import NotificationsQueue

@main
struct VroomVroomTVApp: App {

  let store = Store(initialState: Root.State()) {
    Root()
  }

  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
    }
  }
}

final class VroomAppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
    sceneConfig.delegateClass = VroomSceneDelegate.self
    return sceneConfig
  }
}

final class VroomSceneDelegate: UIResponder, UIWindowSceneDelegate, ObservableObject {

  var notificationQueueWindow: UIWindow?
  weak var windowScene: UIWindowScene?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions) {
    windowScene = scene as? UIWindowScene
  }

  func setupNotificationQueueWindow(with store: StoreOf<Root>) {
    guard let windowScene else { return }

    let hostingController = UIHostingController(
      rootView: NotificationsQueueView(store: store.scope(
        state: \.notificationQueueState, action: Root.Action.notificationQueue)))

    hostingController.view.backgroundColor = .clear

    let window = PassthroughWindow(windowScene: windowScene)
    window.rootViewController = hostingController
    window.isHidden = false
    self.notificationQueueWindow = window
  }
}

final class PassthroughWindow: UIWindow {
  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    guard let hitView = super.hitTest(point, with: event) else { return nil }
    return rootViewController?.view == hitView ? nil : hitView
  }
}
