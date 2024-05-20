//
//  Widgets.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import APIClient
import LandinhoFoundation
import ComposableArchitecture
import Foundation

public struct Widgets: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(categoryTag: String?) {
      self.categoryTag = categoryTag
    }

    let categoryTag: String?
    public var racesState = APIClient<Race>.State(endpoint: "next-race")
  }

  public enum Action: Equatable {
    case racesRequest(APIClient<Race>.Action)
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

