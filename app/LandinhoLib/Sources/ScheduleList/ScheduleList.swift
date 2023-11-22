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
import WidgetUI

// TODO: Move to Common
public struct Page<T: Codable & Equatable & Identifiable>: Codable, Equatable {
  let items: [T]
  let metadata: Metadata

  public struct Metadata: Codable, Equatable {
    let page: Int
    let per: Int
    let total: Int
  }
}

// TODO: Fetch next races, paginate
public struct ScheduleList: Reducer {

  public init() {}

  public struct State: Equatable {
    public init(categoryTag: String?) {
      self.categoryTag = categoryTag
    }

    let categoryTag: String?
    public var racesState = APIClient<Page<MegaRace>>.State(endpoint: "next-races")
  }

  public enum Action: Equatable {
    case onAppear
    case delegate(DelegateAction)
    case racesRequest(APIClient<Page<MegaRace>>.Action)
  }

  public enum DelegateAction: Equatable {
    case onWidgetTap(MegaRace)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .send(.racesRequest(.request(.get([
          "category": state.categoryTag ?? "",
          "page": "0",
          "per": "5"
        ]))))
      case .racesRequest, .delegate:
        return .none
      }
    }

    Scope(state: \.racesState, action: /Action.racesRequest) {
      APIClient()
    }
  }
}

