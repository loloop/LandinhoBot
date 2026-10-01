//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Categories
import ComposableArchitecture
import Foundation
import LandinhoFoundation
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
    public var selectedTab: Tab = .home
    var lastOpenedRoute: AppRoute?
  }

  public enum Tab: Hashable { case home, categories, settings }

  public enum Action: Equatable {
    case onAppear
    case selectTab(Tab)
    case openRoute(AppRoute)

    case path(StackAction<Path.State, Path.Action>)
    case categories(Categories.Action)
    case home(Home.Action)
    case settings(Settings.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectTab(let tab):
        state.selectedTab = tab
        state.lastOpenedRoute = nil
        return .none

      case .openRoute(let route):
        guard route.url != nil else { return .none }
        // Delivering the same URL twice must not add a second detail screen or restart its request.
        if state.lastOpenedRoute == route { return .none }
        state.lastOpenedRoute = route
        state.path.removeAll()
        switch route {
        case .home: state.selectedTab = .home
        case .categories: state.selectedTab = .categories
        case .settings: state.selectedTab = .settings
        case .category(let tag):
          state.selectedTab = .categories
          state.path.append(.scheduleList(.init(categoryTag: tag)))
        case .round(let id):
          state.selectedTab = .home
          state.path.append(.eventDetail(.init(raceID: id)))
        }
        return .none

      case
          .home(.scheduleList(.delegate(.onWidgetTap(let race)))),
          .path(.element(id: _, action: .scheduleList(.delegate(.onWidgetTap(let race))))):
        state.lastOpenedRoute = nil
        state.path.append(.eventDetail(.init(race: race)))
        return .none

      case 
          .home(.scheduleList(.delegate(.onShareTap(let race)))),
          .path(.element(id: _, action: .eventDetail(.delegate(.onShareTap(let race))))),
          .path(.element(id: _, action: .scheduleList(.delegate(.onShareTap(let race))))):
        state.lastOpenedRoute = nil
        state.path.append(.sharing(.init(race: race)))
        return .none

      case .onAppear:
        guard state.categoriesState.categoriesState.response == .idle else { return .none }
        return .send(.categories(.categoriesRequest(.request(.get))))

      case .categories(.delegate(.favoritesChanged(let tags))):
        return .send(.home(.scheduleList(.favoritesChanged(tags))))

      case .categories(.onCategoryTap(let tag)):
        state.lastOpenedRoute = nil
        state.path.append(.scheduleList(.init(categoryTag: tag)))
        return .none

      case .path(.popFrom):
        state.lastOpenedRoute = nil
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
    WithViewStore(store, observe: \.selectedTab) { viewStore in
      TabView(selection: viewStore.binding(send: Router.Action.selectTab)) {
        HomeView(
          store: store.scope(state: \.homeState, action: Router.Action.home)
        )
        .navigationTitle("Home")
        .tabItem {
          Label("Home", systemImage: "flag.checkered")
        }
        .tag(Router.Tab.home)

        CategoriesView(
          store: store.scope(state: \.categoriesState, action: Router.Action.categories)
        )
        .tabItem {
          Label("Categorias", systemImage: "car.side.rear.open")
        }
        .tag(Router.Tab.categories)

        SettingsView(
          store: store.scope(state: \.settingsState, action: Router.Action.settings)
        )
        .tabItem {
          Label("Ajustes", systemImage: "gearshape")
        }
        .tag(Router.Tab.settings)
      }
    }
  }
}
