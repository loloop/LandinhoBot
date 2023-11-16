//
//  Categories.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import APIClient
import Common
import Foundation
import ComposableArchitecture
import SwiftUI

// TODO: On tap of a category, @PresentationState present a ScheduleList

public struct Categories: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    public var categoriesState = APIClient<[RaceCategory]>.State(endpoint: "category")
  }

  public enum Action: Equatable {
    case onAppear
    case categoriesRequest(APIClient<[RaceCategory]>.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none
      case .categoriesRequest:
        return .none
      }
    }

    Scope(state: \.categoriesState, action: /Action.categoriesRequest) {
      APIClient()
    }
  }
}

public struct CategoriesView: View {
  public init(store: StoreOf<Categories>) {
    self.store = store
  }

  let store: StoreOf<Categories>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      switch viewStore.categoriesState.response {
      case .idle:
        Text("Idle")
      case .loading:
        ProgressView()
      case .reloading(let categories), .finished(.success(let categories)):
        List(categories) { category in
          HStack {
            VStack(alignment: .leading) {
              Text(category.title)
                .font(.headline)
              // TODO: Request next race for a given category and display it here
              Text("We should show what's the next race here, and its time")
                .font(.caption)
            }
            Spacer()
            // TODO: Add a way to favorite categories
            Image(systemName: "heart")
          }
        }
      case .finished(.failure(let error)):
        APIErrorView(error: error)
      }
    }
  }
}

