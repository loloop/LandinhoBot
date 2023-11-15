//
//  EventsAdmin.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import APIClient
import Common
import ComposableArchitecture
import Foundation
import SwiftUI

public struct UploadRaceRequest: Codable, Equatable {
  let title: String
  let categoryTag: String
  let events: [UploadRaceEvent]
}

public struct UploadRaceEvent: Codable, Equatable, Identifiable {
  public var id = UUID()
  var title: String
  var date: Date
}

public enum UploadRaceEventBundle: Equatable {
  case F1Sprint
  case F1Regular

  var tag: String {
    switch self {
    case .F1Sprint, .F1Regular:
      "f1"
    }
  }

  var events: [UploadRaceEvent] {
    switch self {
    case .F1Sprint:
      [
        .init(title: "Treino Livre", date: Date()),
        .init(title: "Classificação", date: Date()),
        .init(title: "Sprint Shootout", date: Date()),
        .init(title: "Sprint", date: Date()),
        .init(title: "Corrida", date: Date()),
      ]
    case .F1Regular:
      [
        .init(title: "Treino Livre  1", date: Date()),
        .init(title: "Treino Livre 2", date: Date()),
        .init(title: "Treino Livre 3", date: Date()),
        .init(title: "Classificação", date: Date()),
        .init(title: "Corrida", date: Date()),
      ]
    }
  }
}

public struct EventsAdmin: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(id: String, title: String) {
      self.id = id
      self.title = title
    }

    let id: String
    let title: String

    var eventList = APIClient<[RaceEvent]>.State(endpoint: "events")
    @BindingState var events: [UploadRaceEvent] = []

    var hasEditedEventList: Bool {
      eventList.response.value?.compactMap {
        UploadRaceEvent(id: $0.id, title: $0.title, date: $0.date)
      } == events
    }
  }

  public enum Action: Equatable, BindableAction {
    case onAppear
    case saveList
    case addEvent
    case removeEvent(UploadRaceEvent)
    case addBundle(UploadRaceEventBundle)
    case updateEventTitle(UploadRaceEvent, String)
    case updateEventDate(UploadRaceEvent, Date)

    case eventListRequest(APIClient<[RaceEvent]>.Action)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onAppear:
        let id = state.id
        return .run { send in
          await send(.eventListRequest(.request(.get(queryItems: [
            .init(name: "id", value: id)
          ]))))
        }

      case .addBundle(let bundle):
        state.events = bundle.events
        return .none

      case .addEvent:
        if let ev = state.events.last {
          state.events.append(.init(title: "", date: ev.date))
        } else {
          state.events.append(.init(title: "", date: Date()))
        }

        return .none

      case .removeEvent(let event):
        state.events.removeAll(where: { $0 == event })
        return .none

      case .saveList:
        let request = SaveEventListRequest(
          raceID: state.id,
          events: state.events)

        return .run { send in
          try await send(.eventListRequest(.request(.post(request))))
        }

      case .eventListRequest(.response(.finished(.success(let events)))):
        state.events = events.map {
          UploadRaceEvent(id: $0.id, title: $0.title, date: $0.date)
        }
        return .none

      case .updateEventTitle(let event, let title):
        if let idx = state.events.firstIndex(of: event) {
          var eventCopy = event
          eventCopy.title = title
          state.events[idx] = eventCopy
        }

        return .none

      case .updateEventDate(let event, let date):
        if let idx = state.events.firstIndex(of: event) {
          var eventCopy = event
          eventCopy.date = date
          state.events[idx] = eventCopy
        }

        return .none

      case .eventListRequest, .binding:
        return .none
      }
    }

    Scope(state: \.eventList, action: /Action.eventListRequest) {
      APIClient()
    }
  }

  struct SaveEventListRequest: Codable {
    let raceID: String
    let events: [UploadRaceEvent]
  }
}

