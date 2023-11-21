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

    // Root ScheduleList
    var scheduleListState = ScheduleList.State(categoryTag: nil)
    var path = StackState<Path.State>()

  }

  public enum Action: Equatable {
    case onAppear

    case path(StackAction<Path.State, Path.Action>)
    case scheduleList(ScheduleList.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      case 
          .scheduleList(.delegate(.onWidgetTap(let race))),
          .path(.element(id: _, action: .scheduleList(.delegate(.onWidgetTap(let race))))):
        state.path.append(.eventDetail(.init(race: race)))
        return .none

      case .path(.element(id: _, action: .eventDetail(.delegate(.onShareTap(let race, let aspectRatio))))):
        state.path.append(.sharing(.init(race: race, isSquareAspectRatio: aspectRatio)))
        return .none
      case .scheduleList:
        return .none
      case .path:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Path()
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
    NavigationStackStore(
      store.scope(state: \.path, action: { .path($0) })
    ) {
      ScheduleListView(
        store: store.scope(
          state: \.scheduleListState,
          action: Home.Action.scheduleList))
      .navigationTitle("Home")
    } destination: { initialState in
      switch initialState {
      case .scheduleList:
        CaseLet(
          /Home.Path.State.scheduleList,
           action: Home.Path.Action.scheduleList,
           then: ScheduleListView.init(store:))
      case .eventDetail:
        CaseLet(
          /Home.Path.State.eventDetail,
           action: Home.Path.Action.eventDetail,
           then: EventDetailView.init(store:))
      case .sharing:
        CaseLet(
          /Home.Path.State.sharing,
           action: Home.Path.Action.sharing,
           then: SharingView.init(store:))
      }
    }
  }
}

extension Home {
  @Reducer
  public struct Path {
    public init() {}

    public enum State: Equatable {
      case scheduleList(ScheduleList.State)
      case eventDetail(EventDetail.State)
      case sharing(Sharing.State)
    }

    public enum Action: Equatable {
      case scheduleList(ScheduleList.Action)
      case eventDetail(EventDetail.Action)
      case sharing(Sharing.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: \.scheduleList, action: \.scheduleList) {
        ScheduleList()
      }

      Scope(state: \.eventDetail, action: \.eventDetail) {
        EventDetail()
      }

      Scope(state: \.sharing, action: \.sharing) {
        Sharing()
      }
    }
  }
}
