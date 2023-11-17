//
//  Widgets.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import APIClient
import Common
import ComposableArchitecture
import Foundation

public struct Widgets: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(shouldFilterNonMainEvents: Bool, categoryTag: String?) {
      self.shouldFilterNonMainEvents = shouldFilterNonMainEvents
      self.categoryTag = categoryTag
    }

    let categoryTag: String?
    // TODO: Filter non-main events
    let shouldFilterNonMainEvents: Bool
    public var racesState = APIClient<RaceBundle>.State(endpoint: "next-race")
  }

  public enum Action: Equatable {
    case racesRequest(APIClient<RaceBundle>.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .racesRequest:
        return .none
      }
    }
    Scope(state: \.racesState, action: /Action.racesRequest) {
      APIClient()
    }
  }
}

