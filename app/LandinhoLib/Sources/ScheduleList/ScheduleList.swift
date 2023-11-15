//
//  ScheduleList.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import APIClient
import Common
import Foundation
import ComposableArchitecture
import SwiftUI

public struct ScheduleList: Reducer {

  public init() {}

  public struct State: Equatable {
    public init(categoryTag: String?) {
      self.categoryTag = categoryTag
    }

    let categoryTag: String?

    var racesState = APIClient<Race>.State(endpoint: "next-race")
  }

  public enum Action: Equatable {
    case onAppear

    case racesRequest(APIClient<Race>.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.racesRequest(.request(.get)))
      case .racesRequest:
        return .none
      }
    }

    Scope(state: \.racesState, action: /Action.racesRequest) {
      APIClient()
    }
  }
}

public struct ScheduleListView: View {
  public init(store: StoreOf<ScheduleList>) {
    self.store = store
  }

  let store: StoreOf<ScheduleList>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ScrollView {
        VStack {
          switch viewStore.racesState.response {
          case .idle:
            Text("idle")
          case .loading:
            Text("loading")
          case .reloading(let race), .finished(.success(let race)):
            Text("finished or reloading - \(race.title)")
          case .finished(.failure(let error)):
            APIErrorView(error: error)
          }
        }
      }
    }
    .task {
      store.send(.onAppear)
    }
  }
}

