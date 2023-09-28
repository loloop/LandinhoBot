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
    var upload = Upload.State()
    var testRequest = TestRequest.State()
  }

  enum Action: Equatable {
    case upload(Upload.Action)
    case testRequest(TestRequest.Action)
  }

  var body: some ReducerOf<Root> {
    Scope(state: \.upload, action: /Action.upload) {
      Upload()
    }
    Scope(state: \.testRequest, action: /Action.testRequest) {
      TestRequest()
    }
  }
}
