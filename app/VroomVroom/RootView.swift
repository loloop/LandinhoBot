//
//  ContentView.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import BetaSheet
import ComposableArchitecture
import Categories
import Home
import Settings
import SwiftUI

struct RootView: View {

  let store: StoreOf<Root>
  @EnvironmentObject var sceneDelegate: VroomSceneDelegate

  var body: some View {
    WithViewStore(store, observe: \.isPresentingBetaSheet) { viewStore in
      TabView {
        HomeView(
          store: store.scope(state: \.homeState, action: Root.Action.home)
        )
        .tabItem {
          Label("Home", systemImage: "flag.checkered")
        }

        CategoriesView(
          store: store.scope(state: \.categoriesState, action: Root.Action.categories)
        )
        .tabItem {
          Label("Categorias", systemImage: "car.side.rear.open")
        }

        SettingsView(
          store: store.scope(state: \.settingsState, action: Root.Action.settings)
        )
        .tabItem {
          Label("Ajustes", systemImage: "gearshape")
        }
      }
      .sheet(isPresented: viewStore.binding(send: Root.Action.setBetaSheet), content: {
        BetaSheet()
          .interactiveDismissDisabled()
      })
    }
    .task {
      sceneDelegate.setupNotificationQueueWindow(with: store)
      store.send(.onAppear)
    }
  }
}
