//
//  RaceEditor.swift
//
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import APIClient
import ComposableArchitecture
import Foundation

public struct RaceEditor: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(race: RacesAdmin.Race, tag: String) {
      id = race.id
      title = race.title
      shortTitle = race.shortTitle
      isEditing = true
      self.tag = tag
    }

    public init(tag: String) {
      self.tag = tag
      id = ""
      title = ""
      shortTitle = ""
      isEditing = false
    }

    let id: String
    let tag: String
    @BindingState var title: String
    @BindingState var date = Date()
    @BindingState var shortTitle: String

    let isEditing: Bool
    var raceAPI = APIClient<RacesAdmin.Race>.State(endpoint: "race")

    var isSaveInactive: Bool {
      title.isEmpty || raceAPI.response.isLoading
    }
  }

  public enum Action: Equatable, BindableAction {
    case onSaveTap
    case raceRequest(APIClient<RacesAdmin.Race>.Action)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onSaveTap:
        if state.isEditing {
          let request = RacesAdmin.Race(
            id: state.id,
            title: state.title, 
            shortTitle: state.shortTitle,
            earliestEventDate: state.date)
          return .run { send in
            try await send(.raceRequest(.request(.patch(request))))
          }
        } else {
          let request = UploadRaceRequest(
            title: state.title,
            categoryTag: state.tag,
            earliestEventDate: state.date,
            shortTitle: state.shortTitle)
          return .run { send in
            try await send(.raceRequest(.request(.post(request))))
          }
        }

      case .binding(\.$shortTitle):
        state.shortTitle = String(state.shortTitle.prefix(25))
        return .none

      case .binding, .raceRequest:
        return .none
      }
    }

    Scope(state: \.raceAPI, action: /Action.raceRequest) {
      APIClient()
    }
  }

  public struct UploadRaceRequest: Codable, Equatable {
    let title: String
    let categoryTag: String
    let earliestEventDate: Date
    let shortTitle: String
  }
}
