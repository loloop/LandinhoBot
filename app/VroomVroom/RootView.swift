//
//  ContentView.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import ComposableArchitecture
import Categories
import Home
import Settings
import SwiftUI

struct RootView: View {

  let store: StoreOf<Root>

  var body: some View {
    TabView {
      HomeView(
        store: store.scope(state: \.homeState, action: Root.Action.home)
      )
      .tabItem {
        Label("Home", systemImage: "house")
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
    .onAppear {
      store.send(.onAppear)
    }
  }
}
