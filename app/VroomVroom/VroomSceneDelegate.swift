//
//  VroomSceneDelegate.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import ComposableArchitecture
import Foundation
@_spi(Internal) import NotificationsQueue
import UIKit
import SwiftUI

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
