//
//  Categories.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import APIClient
import CategoryFavorites
import CategoryUI
import LandinhoFoundation
import Foundation
import ComposableArchitecture
import ScheduleList
import SwiftUI

@Reducer
public struct Categories {
  public init() {}

  public struct State: Equatable {
    public init() {}

    public var favoriteTags: Set<String> = []
    public var categoriesState = APIClient<[RaceCategory]>.State(endpoint: "category")
  }

  public enum Action: Equatable {
    case onAppear
    case onCategoryTap(String)
    case favoriteTapped(String)
    case delegate(DelegateAction)
    case categoriesRequest(APIClient<[RaceCategory]>.Action)
  }



  public enum DelegateAction: Equatable {
    case favoritesChanged(Set<String>)
  }

  @Dependency(\.categoryFavorites) var favorites

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.favoriteTags = favorites.read()
        return .none

      case .favoriteTapped(let tag):
        state.favoriteTags = favorites.read()
        if !state.favoriteTags.insert(tag).inserted { state.favoriteTags.remove(tag) }
        favorites.write(state.favoriteTags)
        return .send(.delegate(.favoritesChanged(state.favoriteTags)))

      case .delegate:
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
            Button {
              viewStore.send(.onCategoryTap(category.tag))
            } label: {
              HStack {
                CategoryColorSwatch(color: category.resolvedColor)
                  .accessibilityHidden(true)
                VStack(alignment: .leading) {
                  Text(category.title).font(.headline)
                  Text("TODO: Mostrar a próxima corrida da categoria aqui").font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
            .buttonStyle(.plain)

            Button {
              viewStore.send(.favoriteTapped(category.tag))
            } label: {
              Image(systemName: viewStore.favoriteTags.contains(category.tag) ? "heart.fill" : "heart")
                .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel(viewStore.favoriteTags.contains(category.tag) ? "Remover \(category.title) dos favoritos" : "Favoritar \(category.title)")
          }
          .foregroundStyle(.primary)
        }
      case .finished(.failure(let error)):
        APIErrorView(error: error)
      }
    }
    .task { store.send(.onAppear) }
  }
}
