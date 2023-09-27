//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 25/09/23.
//

import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI

// TODO: Modularize

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

public struct UploadRace: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @BindingState var raceTitle: String = ""
    @BindingState var raceTag: String = ""
    @BindingState var events: [UploadRaceEvent] = []
    var raceState = APIClient<UploadRaceRequest>.State.init(endpoint: "race")
  }

  public enum Action: Equatable, BindableAction {
    case uploadRace(APIClient<UploadRaceRequest>.Action)
    case submitRace
    case addEvent
    case updateEventTitle(UploadRaceEvent, String)
    case updateEventDate(UploadRaceEvent, Date)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<UploadRace> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .addEvent:
        state.events.append(.init(title: "", date: Date()))
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

      case .submitRace:
        let request = UploadRaceRequest(
          title: state.raceTitle,
          categoryTag: state.raceTag,
          events: state.events)

        return .run { send in
          try await send(.uploadRace(.request(.post(request))))
        }

      case .uploadRace(.response(.finished)):
        state.raceTitle = ""
        state.raceTag = ""
        state.events = []
        return .none

      case .uploadRace, .binding:
        return .none
      }
    }

    Scope(state: \.raceState, action: /Action.uploadRace) {
      APIClient()
    }
  }
}

public struct UploadRaceView: View {

  public init(store: StoreOf<UploadRace>) {
    self.store = store
  }

  let store: StoreOf<UploadRace>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Section {
        TextField("title", text: viewStore.$raceTitle)
        TextField("tag", text: viewStore.$raceTag)

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
        }

        Button("add event") {
          viewStore.send(.addEvent)
        }

      } header: {
        Text("upload race")
      } footer: {
        Button(action: {
          viewStore.send(.submitRace)
        }, label: {
          HStack {
            Text("Submit")
            if viewStore.raceState.response.isLoading {
              ProgressView()
            }
          }
        })
      }
    }
  }

}
