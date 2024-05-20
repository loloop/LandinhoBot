//
//  Categories.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import APIClient
import LandinhoFoundation
import Foundation
import ComposableArchitecture
import ScheduleList
import SwiftUI

// TODO: On tap of a category, @PresentationState present a ScheduleList

@Reducer
public struct Categories {
  public init() {}

  public struct State: Equatable {
    public init() {}

    public var categoriesState = APIClient<[RaceCategory]>.State(endpoint: "category")
  }

  public enum Action: Equatable {
    case onAppear
    case onCategoryTap(String)
    case categoriesRequest(APIClient<[RaceCategory]>.Action)
  }



  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        return .none

      // TODO: DelegateAction
      case .onCategoryTap:
        return .none
      case .categoriesRequest:
        return .none
      }
    }

    Scope(state: \.categoriesState, action: \.categoriesRequest) {
      APIClient()
    }
  }
}

public struct CategoriesView: View {
  public init(store: StoreOf<Categories>) {
    self.store = store
  }

  let store: StoreOf<Categories>

  @Dependency(\.notificationQueue) var notificationQueue

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      switch viewStore.categoriesState.response {
      case .idle:
        Text("Idle")
      case .loading:
        ProgressView()
      case .reloading(let categories), .finished(.success(let categories)):
        List(categories) { category in
          Button {
            viewStore.send(.onCategoryTap(category.tag))
          } label: {
            HStack {
              VStack(alignment: .leading) {
                Text(category.title)
                  .font(.headline)
                // TODO: Request next race for a given category and display it here
                Text("TODO: Mostrar a próxima corrida da categoria aqui")
                  .font(.caption)
              }
              Spacer()

              Image(systemName: "heart")
                .onTapGesture {
                  // TODO: Add a way to favorite categories
                  notificationQueue.enqueue(.testflight("Ainda não fiz essa funcionalidade, desculpa!"))
                }
            }
          }
          .foregroundStyle(.primary)
        }
      case .finished(.failure(let error)):
        APIErrorView(error: error)
      }
    }

  }
}

