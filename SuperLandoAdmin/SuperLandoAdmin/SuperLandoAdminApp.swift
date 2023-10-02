//
//  SuperLandoAdminApp.swift
//  SuperLandoAdmin
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import ComposableArchitecture
import SwiftUI
import APIClient
import AdminLib

@main
struct SuperLandoAdminApp: App {

  let store: StoreOf<Root> = .init(initialState: .init()) {
    Root()
  }

  var body: some Scene {
    WindowGroup {
      ContentView(store: store)
    }
  }
}

struct Root: Reducer {
  struct State: Equatable {
    var categories = Categories.State()
    var testRequest = TestRequest.State()
  }

  enum Action: Equatable {
    case categories(Categories.Action)
    case testRequest(TestRequest.Action)
  }

  var body: some ReducerOf<Root> {
    Scope(state: \.categories, action: /Action.categories) {
      Categories()
    }
    Scope(state: \.testRequest, action: /Action.testRequest) {
      TestRequest()
    }
  }
}


