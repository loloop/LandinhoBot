//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import ComposableArchitecture
import Foundation
import CategoriesAdmin
import EventsAdmin
import RacesAdmin

public struct Admin: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    var path = StackState<Path.State>()

    var categoriesAdminState = CategoriesAdmin.State()
  }

  public enum Action: Equatable {
    case categoriesAdmin(CategoriesAdmin.Action)

    // TODO: This should probably be refactored to tree-based navigation, no point in keeping it a stack
    // but also no point in refactoring it now
    case path(StackAction<Path.State, Path.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .categoriesAdmin(.onCategoryTap(let id)):
        guard
          let categories = state.categoriesAdminState.categoryList.response.value,
          let selectedCategory = categories.first(where: { $0.id == id })
        else {
          return .none
        }

        state.path.append(
          .racesAdmin(
            .init(title: selectedCategory.title, tag: selectedCategory.tag)
          )
        )
        return .none

      case .path(.element(id: _, action: .racesAdmin(.onRaceTap(let race)))):
        state.path.append(
          .eventsAdmin(
            .init(
              id: race.id,
              title: race.title)
          )
        )
        return .none

      case .categoriesAdmin, .path:
        return .none
      }
    }
    .forEach(\.path, action: /Action.path) {
      Path()
    }

    Scope(state: \.categoriesAdminState, action: /Action.categoriesAdmin) {
      CategoriesAdmin()
    }
  }

  public struct Path: Reducer {
    public init() {}

    public enum State: Equatable {
      case racesAdmin(RacesAdmin.State)
      case eventsAdmin(EventsAdmin.State)
    }

    public enum Action: Equatable {
      case racesAdmin(RacesAdmin.Action)
      case eventsAdmin(EventsAdmin.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.racesAdmin, action: /Action.racesAdmin) {
        RacesAdmin()
      }

      Scope(state: /State.eventsAdmin, action: /Action.eventsAdmin) {
        EventsAdmin()
      }
    }
  }
}



import SwiftUI

public struct AdminView: View {
  public init(store: StoreOf<Admin>) {
    self.store = store
  }

  let store: StoreOf<Admin>

  public var body: some View {
    NavigationStackStore(store.scope(state: \.path, action: Admin.Action.path)) {
      CategoriesAdminView(store: store.scope(
        state: \.categoriesAdminState,
        action: Admin.Action.categoriesAdmin))
    } destination: { state in
      switch state {
      case .racesAdmin:
        CaseLet(
          /Admin.Path.State.racesAdmin,
           action: Admin.Path.Action.racesAdmin,
           then: RacesAdminView.init(store:)
        )

      case .eventsAdmin:
        CaseLet(
          /Admin.Path.State.eventsAdmin,
           action: Admin.Path.Action.eventsAdmin,
           then: EventsAdminView.init(store:)
        )

      }
    }
  }
}
