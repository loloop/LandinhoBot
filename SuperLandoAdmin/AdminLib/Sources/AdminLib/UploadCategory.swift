//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 25/09/23.
//

import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI

// TODO: Modularize

public struct UploadCategoryRequest: Codable, Equatable {
  let title: String
  let categoryTag: String
  let comment: String?
}

public struct UploadCategory: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @BindingState var categoryTitle: String = ""
    @BindingState var categoryTag: String = ""
    @BindingState var categoryComment: String = ""
    var uploadState = APIClient<UploadCategoryRequest>.State(endpoint: "category")
  }

  public enum Action: Equatable, BindableAction {
    case uploadCategory(APIClient<UploadCategoryRequest>.Action)
    case submitCategory
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<UploadCategory> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .submitCategory:
        let request = UploadCategoryRequest(
          title: state.categoryTitle,
          categoryTag: state.categoryTag,
          comment: state.categoryComment)
        return .run { send in
          try await send(.uploadCategory(.request(.post(request))))
        }

      case .uploadCategory(.response(.finished)):
        state.categoryTag = ""
        state.categoryTitle = ""
        state.categoryComment = ""
        return .none

      case .uploadCategory, .binding:
        return .none
      }
    }

    Scope(state: \.uploadState, action: /Action.uploadCategory) {
      APIClient()
    }
  }
}

public struct UploadCategoryView: View {

  public init(store: StoreOf<UploadCategory>) {
    self.store = store
  }

  let store: StoreOf<UploadCategory>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Section {
        TextField("title", text: viewStore.$categoryTitle)
        TextField("tag", text: viewStore.$categoryTag)
        TextField("tag", text: viewStore.$categoryComment)
      } header: {
        Text("upload category")
      } footer: {
        Button(action: {
          viewStore.send(.submitCategory)
        }, label: {
          HStack {
            Text("Submit")
            if viewStore.uploadState.response.isLoading {
              ProgressView()
            }
          }
        })
      }
    }
  }

}
