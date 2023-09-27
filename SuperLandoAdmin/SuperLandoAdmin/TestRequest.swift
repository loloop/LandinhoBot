//
//  TestRequest.swift
//  SuperLandoAdmin
//
//  Created by Mauricio Cardozo on 25/09/23.
//

import APIClient
import Foundation
import ComposableArchitecture
import SwiftUI

struct TestRequest: Reducer {
  struct State: Equatable {
    @BindingState var nextRaceArgument: String = ""
    var nextRaceState = APIClient<NextRaceResponse>.State(endpoint: "next-race")

    var listState = APIClient<NextRaceResponse>.State(endpoint: "list")
  }

  enum Action: Equatable, BindableAction {
    case requestNextRace
    case nextRaceAction(APIClient<NextRaceResponse>.Action)
    case listAction(APIClient<NextRaceResponse>.Action)
    case binding(BindingAction<State>)
  }

  var body: some ReducerOf<TestRequest> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .requestNextRace:
        let query = URLQueryItem(name: "argument", value: state.nextRaceArgument)

        return .send(.nextRaceAction(.request(.get(queryItems: [
          query
        ]))))

      case .nextRaceAction, .listAction, .binding:
        return .none
      }

    }

    Scope(state: \.nextRaceState, action: /Action.nextRaceAction) {
      APIClient()
    }

    Scope(state: \.listState, action: /Action.listAction) {
      APIClient()
    }
  }
}

struct TestRequestView: View {
  let store: StoreOf<TestRequest>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      VStack {
        TextField("next race argument", text: viewStore.$nextRaceArgument)
        Button {
          viewStore.send(.requestNextRace)
        } label: {
          Text("Fetch next race")
        }
        if
          case .finished(.success(let r)) = viewStore.state.nextRaceState.response,
           let race = r.nextRace {
          Text("title: \(race.title)")
          Text("events: ")
          ForEach(race.events) { event in
            Text("\(event.title) at \(event.date.formatted())")
          }
        }
      }
    }
  }
}

struct NextRaceResponse: Codable, Equatable {
  let nextRace: Race?
}

struct Race: Codable, Equatable {
  let id: UUID
  let title: String
  let events: [RaceEvent]
}

struct RaceEvent: Codable, Equatable, Identifiable {
  let id: UUID
  let title: String
  let date: Date
}

