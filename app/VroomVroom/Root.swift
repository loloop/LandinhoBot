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

@Reducer
public struct Root {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var isPresentingBetaSheet = false

    var categoriesState = Categories.State()
    var homeState = Home.State()
    var notificationQueueState = NotificationsQueue.State()
    var settingsState = Settings.State()
  }

  public enum Action: Equatable {
    case onAppear
    case categories(Categories.Action)
    case home(Home.Action)
    case notificationQueue(NotificationsQueue.Action)
    case settings(Settings.Action)
    case setBetaSheet(Bool)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
      let betaSheetKey = "me.mauriciocardozo.racing.vroomvroom.betasheet-v\(version)"

      switch action {
      case .onAppear:
        state.isPresentingBetaSheet = !UserDefaults.standard.bool(forKey: betaSheetKey)
        return .merge(
          .send(.notificationQueue(.observeNotifications)),
          .send(.home(.scheduleList(.racesRequest(.request(.get))))),
          .send(.categories(.categoriesRequest(.request(.get))))
        )

      case .setBetaSheet(let bool):
        if !bool {
          UserDefaults.standard.setValue(true, forKey: betaSheetKey)
        }
        state.isPresentingBetaSheet = bool
        return .none

      case .home, .categories, .notificationQueue, .settings:
        return .none
      }
    }

    Scope(state: \.homeState, action: \.home) {
      Home()
    }

    Scope(state: \.categoriesState, action: \.categories) {
      Categories()
    }

    Scope(state: \.notificationQueueState, action: \.notificationQueue) {
      NotificationsQueue()
    }

    Scope(state: \.settingsState, action: \.settings) {
      Settings()
    }
  }
}

