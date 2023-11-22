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
import Router

struct RootView: View {

  let store: StoreOf<Root>
  @EnvironmentObject var sceneDelegate: VroomSceneDelegate

  var body: some View {
    WithViewStore(store, observe: \.isPresentingBetaSheet) { viewStore in
      RouterView(store: store.scope(state: \.router, action: Root.Action.router))
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
