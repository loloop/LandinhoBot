//
//  CategoriesAdmin.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import APIClient
import Common
import ComposableArchitecture
import Foundation
import EventsAdmin
import RacesAdmin

public struct CategoriesAdmin: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @PresentationState var categoryEditorState: CategoryEditor.State?

    public var categoryList = APIClient<[RaceCategory]>.State(endpoint: "category")
    var path = StackState<Path.State>()
  }

  public enum Action: Equatable {
    case onAppear
    case onPlusTap
    case onCategoryTap(String)
    case onCategoryEditorTap(String)

    case categoryRequest(APIClient<[RaceCategory]>.Action)
    case categoryEditor(PresentationAction<CategoryEditor.Action>)
    case path(StackAction<Path.State, Path.Action>)
  }

  public var body: some ReducerOf<CategoriesAdmin> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          await send(.categoryRequest(.request(.get)))
        }

      case .onCategoryTap:
        // TODO: Add a DelegateAction
        // Used to let parent feature know which one has been tapped
        return .none

      case .onPlusTap:
        state.categoryEditorState = .init()
        return .none

      case .onCategoryEditorTap(let id):
        guard
          let categories = state.categoryList.response.value,
          let selectedCategory = categories.first(where: { $0.id == id })
        else {
          return .none
        }

        state.categoryEditorState = .init(category: selectedCategory)
        return .none

      case .categoryEditor(.presented(.categoryRequest(.response(.finished(.success))))):
        return .merge(
          .send(.onAppear),
          .send(.categoryEditor(.dismiss))
        )

      case .categoryRequest, .categoryEditor, .path:
        return .none
      }
    }
    .ifLet(\.$categoryEditorState, action: /Action.categoryEditor) {
      CategoryEditor()
    }
    .forEach(\.path, action: /Action.path) {
      Path()
    }

    Scope(state: \.categoryList, action: /Action.categoryRequest) {
      APIClient()
    }
  }

  public struct Path: Reducer {
    public init() {}

    public enum State: Equatable {
      case races(RacesAdmin.State)
      case events(EventsAdmin.State)
    }

    public enum Action: Equatable {
      case races(RacesAdmin.Action)
      case events(EventsAdmin.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.races, action: /Action.races) {
        RacesAdmin()
      }

      Scope(state: /State.events, action: /Action.events) {
        EventsAdmin()
      }
    }
  }
}
