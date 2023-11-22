//
//  Settings.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import Admin
import BetaSheet
import Foundation
import ComposableArchitecture
import NotificationsQueue
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

  @Dependency(\.notificationQueue) var notificationQueue

  public var body: some View {
    List {
      NavigationLink {
        BetaSheet()
      } label: {
        Label("Changelog", systemImage: "tree")
      }

      Button {
        // TODO: Link terms of service
        notificationQueue.enqueue(.critical("Ainda não amigo"))
      } label: {
        Label("Termos de Serviço", systemImage: "book.closed")
      }

      Button {
        // TODO: Link privacy policy
        notificationQueue.enqueue(.warning("Ainda não amigo"))
      } label: {
        Label("Política de privacidade", systemImage: "lock")
      }

      Button {
        // TODO: Create developer page
        notificationQueue.enqueue(.success("Ainda não amigo"))
      } label: {
        Label("Sobre o desenvolvedor", systemImage: "person")
      }

      Button {
        store.send(.showAdmin)
      } label: {
        Label("Admin", systemImage: "fuelpump")
      }

      if
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
      {
        HStack {
          Text("Versão")
          Spacer()
          Text("\(version) (\(buildNumber))")
        }
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

#Preview {
  SettingsView(store: .init(initialState: .init(), reducer: {
    Settings()
  }))
}
