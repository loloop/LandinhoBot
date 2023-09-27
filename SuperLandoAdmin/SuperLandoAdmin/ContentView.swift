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
        NavigationLink("upload") {
          UploadView(
            store: store.scope(
              state: \.upload,
              action: Root.Action.upload))
        }

        NavigationLink("test requests") {
          TestRequestView(
            store: store.scope(
              state: \.testRequest,
              action: Root.Action.testRequest))
        }
      }
    } detail: {
      EmptyView()
    }
  }
}
