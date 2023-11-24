//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Categories
import ComposableArchitecture
import Foundation
import EventDetail
import Home
import ScheduleList
import Settings
import Sharing
import SwiftUI

@Reducer
public struct Router {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var categoriesState = Categories.State()
    var homeState = Home.State()
    var settingsState = Settings.State()
    var path = StackState<Path.State>()
  }

  public enum Action: Equatable {
    case onAppear

    case path(StackAction<Path.State, Path.Action>)
    case categories(Categories.Action)
    case home(Home.Action)
    case settings(Settings.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case
          .home(.scheduleList(.delegate(.onWidgetTap(let race)))),
          .path(.element(id: _, action: .scheduleList(.delegate(.onWidgetTap(let race))))):
        state.path.append(.eventDetail(.init(race: race)))
        return .none

      case 
          .home(.scheduleList(.delegate(.onShareTap(let race)))),
          .path(.element(id: _, action: .eventDetail(.delegate(.onShareTap(let race))))),
          .path(.element(id: _, action: .scheduleList(.delegate(.onShareTap(let race))))):
        state.path.append(.sharing(.init(race: race)))
        return .none

      case .onAppear:
        return .merge(
          .send(.home(.scheduleList(.racesRequest(.request(.get))))),
          .send(.categories(.categoriesRequest(.request(.get))))
        )

      case .categories(.onCategoryTap(let tag)):
        state.path.append(.scheduleList(.init(categoryTag: tag)))
        return .none

      case .path, .categories, .home, .settings:
        return .none
      }
    }
    .forEach(\.path, action: \.path) {
      Path()
    }

    Scope(state: \.homeState, action: \.home) {
      Home()
    }

    Scope(state: \.categoriesState, action: \.categories) {
      Categories()
    }

    Scope(state: \.settingsState, action: \.settings) {
      Settings()
    }
  }
}

extension Router {
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


public struct RouterView: View {
  public init(store: StoreOf<Router>) {
    self.store = store
  }

  let store: StoreOf<Router>

  public var body: some View {
    NavigationStackStore(
      store.scope(state: \.path, action: { .path($0) })
    ) {
      InnerRouterView(store: store)
    } destination: { initialState in
      switch initialState {
      case .scheduleList:
        CaseLet(
          /Router.Path.State.scheduleList,
           action: Router.Path.Action.scheduleList,
           then: ScheduleListView.init(store:))
      case .eventDetail:
        CaseLet(
          /Router.Path.State.eventDetail,
           action: Router.Path.Action.eventDetail,
           then: EventDetailView.init(store:))
      case .sharing:
        CaseLet(
          /Router.Path.State.sharing,
           action: Router.Path.Action.sharing,
           then: SharingView.init(store:))
      }
    }
    .task {
      store.send(.onAppear)
    }
  }
}

public struct InnerRouterView: View {
  public init(store: StoreOf<Router>) {
    self.store = store
  }

  let store: StoreOf<Router>

  public var body: some View {
    TabView {
      HomeView(
        store: store.scope(state: \.homeState, action: Router.Action.home)
      )
      .navigationTitle("Categorias")
      .tabItem {
        Label("Home", systemImage: "flag.checkered")
      }

      CategoriesView(
        store: store.scope(state: \.categoriesState, action: Router.Action.categories)
      )
      .tabItem {
        Label("Categorias", systemImage: "car.side.rear.open")
      }

      SettingsView(
        store: store.scope(state: \.settingsState, action: Router.Action.settings)
      )
      .tabItem {
        Label("Ajustes", systemImage: "gearshape")
      }
    }
  }
}
