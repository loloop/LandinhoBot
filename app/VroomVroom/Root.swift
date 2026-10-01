//
//  Root.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import Categories
import ComposableArchitecture
import Foundation
import Home
@_spi(Internal) import NotificationsQueue
import Settings
import SwiftUI
import Router
import LandinhoFoundation

@Reducer
public struct Root {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var isPresentingBetaSheet = false
    var notificationQueueState = NotificationsQueue.State()
    var router = Router.State()
    var hasAppeared = false
    var pendingRoute: AppRoute?
  }

  public enum Action: Equatable {
    case onAppear
    case notificationQueue(NotificationsQueue.Action)
    case setBetaSheet(Bool)
    case router(Router.Action)
    case openURL(URL)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
      let betaSheetKey = "me.mauriciocardozo.racing.vroomvroom.betasheet-v\(version)"

      switch action {
      case .onAppear:
        guard !state.hasAppeared else { return .none }
        state.hasAppeared = true
        state.isPresentingBetaSheet = !UserDefaults.standard.bool(forKey: betaSheetKey)
        let route = state.isPresentingBetaSheet ? nil : state.pendingRoute
        if route != nil { state.pendingRoute = nil }
        return .merge(
          .send(.notificationQueue(.observeNotifications)),
          route.map { .send(.router(.openRoute($0))) } ?? .none)

      case .openURL(let url):
        guard let route = AppRoute(url: url) else { return .none }
        if !state.hasAppeared || state.isPresentingBetaSheet {
          // Latest invocation wins while the first-launch sheet covers navigation.
          state.pendingRoute = route
          return .none
        }
        return .send(.router(.openRoute(route)))

      case .setBetaSheet(let bool):
        if !bool {
          UserDefaults.standard.setValue(true, forKey: betaSheetKey)
        }
        state.isPresentingBetaSheet = bool
        if !bool, let route = state.pendingRoute {
          state.pendingRoute = nil
          return .send(.router(.openRoute(route)))
        }
        return .none

      case .notificationQueue, .router:
        return .none
      }
    }

    Scope(state: \.notificationQueueState, action: \.notificationQueue) {
      NotificationsQueue()
    }

    Scope(state: \.router, action: \.router) {
      Router()
    }
  }
}
