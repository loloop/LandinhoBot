//
//  Categories.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

import APIClient
import CalendarStore
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
    public var categoriesState = APIClient<[RaceCategory]>.State(endpoint: "category", preserveResponseOnFailure: true)
    public var hasStarted = false
    public var lastUpdatedDate: Date?
  }

  public enum Action: Equatable {
    case onAppear
    case refresh
    case savedCategories(SavedCalendar<[RaceCategory]>?)
    case onCategoryTap(String)
    case favoriteTapped(String)
    case delegate(DelegateAction)
    case categoriesRequest(APIClient<[RaceCategory]>.Action)
  }



  public enum DelegateAction: Equatable {
    case favoritesChanged(Set<String>)
  }

  @Dependency(\.categoryFavorites) var favorites
  @Dependency(\.calendarStore) var calendarStore
  @Dependency(\.date.now) var now

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        state.favoriteTags = favorites.read()
        guard !state.hasStarted else { return .none }
        state.hasStarted = true
        return .run { send in
          await send(.savedCategories(try? await calendarStore.loadCategories()))
          await send(.categoriesRequest(.refresh(.get)))
        }

      case .savedCategories(let saved):
        guard state.categoriesState.response == .idle, let saved else { return .none }
        state.categoriesState.response = .finished(.success(saved.value))
        state.lastUpdatedDate = saved.updatedAt
        return .none

      case .refresh:
        guard case .finished = state.categoriesState.response else { return .none }
        return .send(.categoriesRequest(.refresh(.get)))

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
      case .categoriesRequest(.response(.finished(.success(let categories)))):
        state.lastUpdatedDate = now
        let updatedAt = now
        return .run { _ in try? await calendarStore.saveCategories(categories, updatedAt) }
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
      VStack(spacing: 0) {
        if viewStore.categoriesState.lastError != nil, viewStore.categoriesState.response.value != nil {
          Text("Não foi possível atualizar. Exibindo categorias salvas.")
            .font(.caption)
            .padding()
        }
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
                  .foregroundStyle(.tint)
                  .frame(minWidth: 44, minHeight: 44)
              }
              .buttonStyle(.borderless)
              .accessibilityLabel(viewStore.favoriteTags.contains(category.tag) ? "Remover \(category.title) dos favoritos" : "Favoritar \(category.title)")
            }
            .foregroundStyle(.primary)
            .categoryAccent(category.resolvedColor)
          }
        case .finished(.failure(let error)):
          APIErrorView(error: error)
        }
      }
      .refreshable { await viewStore.send(.refresh).finish() }
    }
    .task { store.send(.onAppear) }
  }
}
