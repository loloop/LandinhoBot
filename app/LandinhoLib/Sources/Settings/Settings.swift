//
//  Settings.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Admin
import Foundation
import ComposableArchitecture
import SwiftUI



public struct Settings: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var adminState = Admin.State()
  }

  public enum Action: Equatable {
    case admin(Admin.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .admin:
        return .none
      }
    }

    Scope(state: \.adminState, action: /Action.admin) {
      Admin()
    }
  }
}

public struct SettingsView: View {
  public init(store: StoreOf<Settings>) {
    self.store = store
  }

  let store: StoreOf<Settings>

  public var body: some View {
    // TODO: Create an actual settings view instead of just encapsulating Admin
    AdminView(store: store.scope(
      state: \.adminState,
      action: Settings.Action.admin)
    )
  }
}

