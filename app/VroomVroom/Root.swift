//
//  Root.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import Foundation
import Categories
import ComposableArchitecture
import Home
import Settings
import SwiftUI

public struct Root: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var isPresentingBetaSheet = false
    var homeState = Home.State()
    var categoriesState = Categories.State()
    var settingsState = Settings.State()
  }

  public enum Action: Equatable {
    case onAppear
    case home(Home.Action)
    case categories(Categories.Action)
    case settings(Settings.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
      let betaSheetKey = "me.mauriciocardozo.vroomvroom.betasheet-v\(version)"

      switch action {
      case .onAppear:
        state.isPresentingBetaSheet = !UserDefaults.standard.bool(forKey: betaSheetKey)
        return .merge(
          .send(.home(.scheduleList(.racesRequest(.request(.get))))),
          .send(.categories(.categoriesRequest(.request(.get))))
        )
      case .home, .categories, .settings:
        return .none
      }
    }

    Scope(state: \.homeState, action: /Action.home) {
      Home()
    }

    Scope(state: \.categoriesState, action: /Action.categories) {
      Categories()
    }

    Scope(state: \.settingsState, action: /Action.settings) {
      Settings()
    }
  }
}

