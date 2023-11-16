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

    public var racesState = APIClient<ScheduleListResponse>.State(endpoint: "next-race")
  }

  public enum Action: Equatable {
    case onAppear

    case racesRequest(APIClient<ScheduleListResponse>.Action)
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

  public struct ScheduleListResponse: Codable, Equatable {
    public init(categoryComment: String, nextRace: Race) {
      self.categoryComment = categoryComment
      self.nextRace = nextRace
    }

    public init() {
      // init for placeholder widget views
      categoryComment = ""
      nextRace = Race(
        id: UUID(),
        title: "Placeholder",
        events: [
          .init(id: UUID(), title: "Placeholder", date: Date()),
          .init(id: UUID(), title: "Placeholder", date: Date()),
          .init(id: UUID(), title: "Placeholder", date: Date().advanced(by: 100000)),
          .init(id: UUID(), title: "Placeholder", date: Date().advanced(by: 100000)),
          .init(id: UUID(), title: "Placeholder", date: Date().advanced(by: 200000)),
        ])
    }

    public let categoryComment: String
    public let nextRace: Race
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

// TODO: This should not take in an 'internal' model
public struct ScheduleListItem: View {
  public init(_ response: ScheduleList.ScheduleListResponse) {
    self.response = response
  }

  let response: ScheduleList.ScheduleListResponse

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


