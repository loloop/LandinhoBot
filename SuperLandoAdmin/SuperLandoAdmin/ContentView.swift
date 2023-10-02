//
//  ContentView.swift
//  SuperLandoAdmin
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import ComposableArchitecture
import SwiftUI
import AdminLib

// TODO: TCA StackState

struct ContentView: View {

  let store: StoreOf<Root>

  var body: some View {
    NavigationSplitView {
      List {
        NavigationLink("Home") {
          TestRequestView(
            store: store.scope(
              state: \.testRequest,
              action: Root.Action.testRequest))
        }
        NavigationLink("Categories") {
          CategoryListView(
            store: store.scope(
              state: \.categories,
              action: Root.Action.categories))
        }
      }
      .navigationTitle("Super Lando Admin")
    } detail: {
      ContentUnavailableView(
        "Choose a menu item",
        systemImage: "brain.head.profile",
        description: Text("sorry the default is unimplemented lmao"))
    }
  }
}
