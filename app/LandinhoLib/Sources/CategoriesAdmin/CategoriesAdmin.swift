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
import RacesAdmin

import EventsAdmin

extension CategoriesAdmin {
  @Reducer
  public struct Destination {
    public init() {}

    public enum State: Equatable {
      case categoryEditor(CategoryEditor.State)
      case racesAdmin(RacesAdmin.State)
    }

    public enum Action: Equatable {
      case categoryEditor(CategoryEditor.Action)
      case racesAdmin(RacesAdmin.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: \.categoryEditor, action: \.categoryEditor) {
        CategoryEditor()
      }

      Scope(state: \.racesAdmin, action: \.racesAdmin) {
        RacesAdmin()
      }
    }
  }
}

@Reducer
public struct CategoriesAdmin {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @PresentationState var destination: Destination.State?

    public var categoryList = APIClient<[RaceCategory]>.State(endpoint: "category")
  }

  public enum Action: Equatable {
    case onAppear
    case onPlusTap
    case onCategoryTap(String)
    case onCategoryEditorTap(String)

    case categoryRequest(APIClient<[RaceCategory]>.Action)
    case destination(PresentationAction<Destination.Action>)
  }

  public var body: some ReducerOf<CategoriesAdmin> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .run { send in
          await send(.categoryRequest(.request(.get)))
        }

      case .onCategoryTap(let id):
        guard
          let categories = state.categoryList.response.value,
          let selectedCategory = categories.first(where: { $0.id == id })
        else {
          return .none
        }

        state.destination = .racesAdmin(
          .init(
            title: selectedCategory.title,
            tag: selectedCategory.tag))
        return .none

      case .onPlusTap:
        state.destination = .categoryEditor(.init())
        return .none

      case .onCategoryEditorTap(let id):
        guard
          let categories = state.categoryList.response.value,
          let selectedCategory = categories.first(where: { $0.id == id })
        else {
          return .none
        }

        state.destination = .categoryEditor(.init(category: selectedCategory))
        return .none

      case .destination(.presented(.categoryEditor(.categoryRequest(.response(.finished(.success)))))):
        return .merge(
          .send(.onAppear),
          .send(.destination(.dismiss))
        )

      case .categoryRequest, .destination:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }

    Scope(state: \.categoryList, action: /Action.categoryRequest) {
      APIClient()
    }
  }
}
