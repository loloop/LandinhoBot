//
//  Home.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import ComposableArchitecture
import EventDetail
import Foundation
import SwiftUI
import ScheduleList
import Sharing

@Reducer
public struct Home {
  public init() {}

  public struct State: Equatable {
    public init() {}
    var scheduleListState = ScheduleList.State(categoryTag: nil)
  }

  public enum Action: Equatable {
    case onAppear
    case scheduleList(ScheduleList.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      case .scheduleList:
        return .none
      }
    }

    Scope(state: \.scheduleListState, action: /Action.scheduleList) {
      ScheduleList()
    }
  }
}

public struct HomeView: View {
  public init(store: StoreOf<Home>) {
    self.store = store
  }

  let store: StoreOf<Home>

  public var body: some View {
      ScheduleListView(
        store: store.scope(
          state: \.scheduleListState,
          action: Home.Action.scheduleList))
    .navigationTitle("Home") // TODO: Figure out why this is not getting applied
  }
}
