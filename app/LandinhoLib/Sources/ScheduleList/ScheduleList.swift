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

// TODO: Fetch next races, paginate
public struct ScheduleList: Reducer {

  public init() {}

  public struct State: Equatable {
    public init(categoryTag: String?) {
      self.categoryTag = categoryTag
    }

    let categoryTag: String?
    public var racesState = APIClient<RaceBundle>.State(endpoint: "next-race")
  }

  public enum Action: Equatable {
    case onAppear
    case racesRequest(APIClient<RaceBundle>.Action)
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
      List {
        switch viewStore.racesState.response {
        case .idle:
          EmptyView()
        case .loading:
          ProgressView()
        case .reloading(let response), .finished(.success(let response)):
          ScheduleListItem(response)
            .padding(.vertical)
        case .finished(.failure(let error)):
          APIErrorView(error: error)
        }
      }
    }
    .task {
      store.send(.onAppear)
    }
  }
}

public struct ScheduleListItem: View {
  public init(_ response: RaceBundle) {
    self.response = response
  }

  let response: RaceBundle

  public var body: some View {
    VStack(alignment: .leading) {
      Text("Category title")
        .font(.callout)

      Text(response.nextRace.title)
        .font(.title3)

      HStack {
        RoundedRectangle(cornerRadius: 25.0, style: .continuous)
          .frame(maxWidth: 100)

        Spacer()
        VStack(alignment: .leading) {


          ForEach(response.nextRace.events) { event in
            HStack {
              Text(event.title)
              Text(event.date.formatted())
            }
            .font(.caption)
          }
        }
      }
    }
  }
}


