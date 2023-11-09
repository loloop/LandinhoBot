//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 02/10/23.
//

import APIClient
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
        .init(title: "Qualifying", date: Date()),
        .init(title: "Sprint Shootout", date: Date()),
        .init(title: "Sprint", date: Date()),
        .init(title: "Corrida", date: Date()),
      ]
    case .F1Regular:
      [
        .init(title: "Treino Livre  1", date: Date()),
        .init(title: "Treino Livre 2", date: Date()),
        .init(title: "Treino Livre 3", date: Date()),
        .init(title: "Qualifying", date: Date()),
        .init(title: "Corrida", date: Date()),
      ]
    }
  }
}

public struct Events: Reducer {
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
        if let ev = state.events.first {
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

import APIRequester
public struct EventListView: View {
  public init(store: StoreOf<Events>) {
    self.store = store
  }

  let store: StoreOf<Events>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        switch viewStore.eventList.response {
        case .idle, .loading, .reloading:
          ProgressView()
        case .finished(.failure(let error)):
          ContentUnavailableView(
            "Something went wrong",
            systemImage: "xmark.octagon",
            description: Text((error as? APIError)?.jsonString ?? ""))
        case .finished(.success):
          if viewStore.events.isEmpty {
            VStack {
              ContentUnavailableView(
                "This race has no events",
                systemImage: "magnifyingglass")
              Button("Add event") {
                viewStore.send(.addEvent)
              }
            }
          } else {
            List {
              ForEach(viewStore.events) { event in
                HStack {
                  TextField(
                    "title",
                    text: viewStore.binding(get: { state in
                      if let idx = state.events.firstIndex(of: event) {
                        return state.events[idx].title
                      }

                      return "error"
                    }) { newValue in
                        .updateEventTitle(event, newValue)
                    })

                  DatePicker(
                    "date",
                    selection: viewStore.binding(get: { state in
                      if let idx = state.events.firstIndex(of: event) {
                        return state.events[idx].date
                      }

                      print("date error")
                      return Date()
                    }) { newValue in
                        .updateEventDate(event, newValue)
                    })
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                  Button("Delete", role: .destructive) {
                    viewStore.send(.removeEvent(event))
                  }
                }

              }
              Button("Add event") {
                viewStore.send(.addEvent)
              }
            }
          }
        }
      }
      .navigationTitle(viewStore.title)
      .toolbarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .secondaryAction) {
          Button("Add F1 Weekend") {
            viewStore.send(.addBundle(.F1Regular))
          }
        }

        ToolbarItem(placement: .secondaryAction) {
          Button("Add F1 Sprint Weekend") {
            viewStore.send(.addBundle(.F1Sprint))
          }
        }

        ToolbarItem {
          Button("Save") {
            viewStore.send(.saveList)
          }
          .disabled(viewStore.hasEditedEventList)
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }
}


