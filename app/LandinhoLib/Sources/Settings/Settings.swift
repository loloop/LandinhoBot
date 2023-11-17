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

@Reducer
public struct Settings {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @PresentationState var adminState: Admin.State?
  }

  public enum Action: Equatable {
    case showAdmin
    case admin(PresentationAction<Admin.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showAdmin:
        state.adminState = .init()
        return .none

      case .admin:
        return .none
      }
    }
    .ifLet(\.$adminState, action: \.admin) {
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
    NavigationStack {
      List {
        Button {

        } label: {
          Label("Changelog", systemImage: "")
        }
        Button {

        } label: {
          Label("Termos de Serviço", systemImage: "")
        }
        Button {
          store.send(.showAdmin)
        } label: {
          Label("Admin", systemImage: "fuelpump")
        }
      }
      .navigationTitle("Ajustes")
      .navigationDestination(store: store.scope(
        state: \.$adminState,
        action: { .admin($0) } )
      ) { store in
        AdminView(store: store)
      }
    }
  }
}
