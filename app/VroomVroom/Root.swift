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

@Reducer
public struct Root {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var isPresentingBetaSheet = false
    var notificationQueueState = NotificationsQueue.State()
    var router = Router.State()
  }

  public enum Action: Equatable {
    case onAppear
    case notificationQueue(NotificationsQueue.Action)
    case setBetaSheet(Bool)
    case router(Router.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
      let betaSheetKey = "me.mauriciocardozo.racing.vroomvroom.betasheet-v\(version)"

      switch action {
      case .onAppear:
        state.isPresentingBetaSheet = !UserDefaults.standard.bool(forKey: betaSheetKey)
        return .send(.notificationQueue(.observeNotifications))

      case .setBetaSheet(let bool):
        if !bool {
          UserDefaults.standard.setValue(true, forKey: betaSheetKey)
        }
        state.isPresentingBetaSheet = bool
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

