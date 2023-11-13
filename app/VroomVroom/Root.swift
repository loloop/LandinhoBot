//
//  Root.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import Foundation
import Categories
import ComposableArchitecture
import Settings
import SwiftUI

public struct Root: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var isPresentingBetaSheet = false
  }

  public enum Action: Equatable {
    case onAppear
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      let version = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "x"
      let betaSheetKey = "me.mauriciocardozo.vroomvroom.betasheet-v\(version)"

      switch action {
      case .onAppear:
        state.isPresentingBetaSheet = !UserDefaults.standard.bool(forKey: betaSheetKey)
        return .none
      }
    }
  }
}

struct RootView: View {

  let store: StoreOf<Root>

  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Label("Home", systemImage: "house")
        }

      CategoriesView()
        .tabItem {
          Label("Categories", systemImage: "car.side.rear.open")
        }

      SettingsView()
        .tabItem {
          Label("Settings", systemImage: "gearshape")
        }
    }
  }
}
