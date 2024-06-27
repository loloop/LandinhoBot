//
//  CategoryEditor.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import APIClient
import LandinhoFoundation
import ComposableArchitecture
import Foundation

public struct CategoryEditor: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(category: RaceCategory) {
      id = category.id
      title = category.title
      tag = category.tag
      comment = category.comment ?? ""
      isEditing = true
    }

    public init() {
      id = ""
      title = ""
      tag = ""
      comment = ""
      isEditing = false
    }

    let id: String
    @BindingState var title: String
    @BindingState var tag: String
    @BindingState var comment: String

    let isEditing: Bool

    var categoryAPI = APIClient<RaceCategory>.State(endpoint: "category")
  }

  public enum Action: Equatable, BindableAction {
    case onSaveTap
    case categoryRequest(APIClient<RaceCategory>.Action)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onSaveTap:
        if state.isEditing {
          let request = RaceCategory(
            id: state.id,
            title: state.title,
            tag: state.tag,
            comment: state.comment)
          return .run { send in
            try await send(.categoryRequest(.request(.patch(request))))
          }

        } else {
          let request = UploadCategoryRequest(
            title: state.title,
            categoryTag: state.tag,
            comment: state.comment)
          return .run { send in
            try await send(.categoryRequest(.request(.post(request))))
          }
        }

      case .binding, .categoryRequest:
        return .none
      }
    }

    Scope(state: \.categoryAPI, action: /Action.categoryRequest) {
      APIClient()
    }
  }

  public struct UploadCategoryRequest: Codable, Equatable {
    let title: String
    let categoryTag: String
    let comment: String?
  }
}

