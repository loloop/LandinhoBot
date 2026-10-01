//
//  VroomSceneDelegate.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import ComposableArchitecture
import Foundation
import LandinhoFoundation
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
  private var rootStore: StoreOf<Root>?
  private var pendingShortcutURL: URL?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions) {
    windowScene = scene as? UIWindowScene
    if let shortcutItem = connectionOptions.shortcutItem {
      handleQuickAction(shortcutItem)
    }
  }

  func windowScene(
    _ windowScene: UIWindowScene,
    performActionFor shortcutItem: UIApplicationShortcutItem,
    completionHandler: @escaping (Bool) -> Void
  ) {
    completionHandler(handleQuickAction(shortcutItem))
  }

  func bindRootStore(_ store: StoreOf<Root>) {
    rootStore = store
    if let url = pendingShortcutURL {
      // Clear before sending so repeated SwiftUI tasks cannot replay a launch action.
      pendingShortcutURL = nil
      store.send(.openURL(url))
    }
  }

  @discardableResult
  func handleQuickAction(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
    guard let action = HomeScreenQuickAction(rawValue: shortcutItem.type),
      let url = action.route.url else { return false }

    if let rootStore {
      rootStore.send(.openURL(url))
    } else {
      // Root owns startup/BetaSheet deferral once this scene's store is available.
      pendingShortcutURL = url
    }
    return true
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
