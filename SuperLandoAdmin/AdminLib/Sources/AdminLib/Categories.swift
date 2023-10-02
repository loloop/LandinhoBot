//
//  File.swift
//
//
//  Created by Mauricio Cardozo on 29/09/23.
//

import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI

public struct Categories: Reducer {
  public init() {}

  public struct State: Equatable {
    public init() {}

    @PresentationState var categoryEditorState: CategoryEditor.State?

    var categoryList = APIClient<[Category]>.State(endpoint: "category")
    var path = StackState<Path.State>()
  }

  public enum Action: Equatable {
    case onAppear
    case onPlusTap
    case onCategoryTap(String)
    case onCategoryEditorTap(String)

    case categoryRequest(APIClient<[Category]>.Action)
    case categoryEditor(PresentationAction<CategoryEditor.Action>)
    case path(StackAction<Path.State, Path.Action>)
  }

  public var body: some ReducerOf<Categories> {
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

        state.path.append(.races(.init(title: selectedCategory.title, tag: selectedCategory.tag)))

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
      case races(Races.State)
      case events(Events.State)
    }

    public enum Action: Equatable {
      case races(Races.Action)
      case events(Events.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: /State.races, action: /Action.races) {
        Races()
      }

      Scope(state: /State.events, action: /Action.events) {
        Events()
      }
    }
  }
}

public struct CategoryListView: View {
  public init(store: StoreOf<Categories>) {
    self.store = store
  }

  let store: StoreOf<Categories>

  public var body: some View {
    NavigationStackStore(store.scope(state: \.path, action: Categories.Action.path)) {
      InnerCategoryListView(store: store)
    } destination: { state in
      switch state {
      case .races:
        CaseLet(
          /Categories.Path.State.races,
           action: Categories.Path.Action.races,
           then: {
             RaceListView(store: $0)
           })
      case .events:
        CaseLet(
          /Categories.Path.State.events,
           action: Categories.Path.Action.events,
           then: {
             EventListView(store: $0)
           })
      }
    }
  }
}

public struct InnerCategoryListView: View {
  public init(store: StoreOf<Categories>) {
    self.store = store
  }

  let store: StoreOf<Categories>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      switch viewStore.categoryList.response {
      case .idle, .loading, .reloading:
        ProgressView()
      case .finished(.failure(let error)):
        ContentUnavailableView(
          "Something went wrong",
          systemImage: "xmark.octagon",
          description: Text(error.localizedDescription))
      case .finished(.success(let categories)):
        List {
          ForEach(categories) { category in

            HStack {
              VStack(alignment: .leading) {
                Text(category.title)
                  .font(.title3)
                Text(category.comment ?? "")
                  .font(.subheadline)
                Text(category.tag)
                  .font(.caption)
              }
              Spacer()
              // TODO: change to NavigationLink
              Image(systemName: "chevron.right")
            }
            .contextMenu {
              Button("Edit") {
                viewStore.send(.onCategoryEditorTap(category.id))
              }
            }
            .onTapGesture {
              viewStore.send(.onCategoryTap(category.id))
            }

          }
        }
      }
    }
    .navigationTitle("Categories")
    .navigationBarTitleDisplayMode(.large)
    .onAppear {
      store.send(.onAppear)
    }
    .toolbar {
      ToolbarItem {
        Button(action: {
          store.send(.onPlusTap)
        }, label: {
          Image(systemName: "plus")
        })
      }
    }
    .sheet(
      store: store
        .scope(
          state: { $0.$categoryEditorState },
          action: Categories.Action.categoryEditor)) { store in
            CategoryEditorView(store: store)
          }
  }
}

public struct CategoryEditor: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(category: Category) {
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

    var categoryAPI = APIClient<Category>.State(endpoint: "category")
  }

  public enum Action: Equatable, BindableAction {
    case onSaveTap
    case categoryRequest(APIClient<Category>.Action)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onSaveTap:
        if state.isEditing {
          let request = Category(
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

public struct CategoryEditorView: View {
  public init(store: StoreOf<CategoryEditor>) {
    self.store = store
  }

  let store: StoreOf<CategoryEditor>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        List {
          HStack {
            Text("Title")
            TextField("Title", text: viewStore.$title)
          }
          HStack {
            Text("Tag")
            TextField("Tag", text: viewStore.$tag)
          }
          HStack {
            Text("Comment")
            TextField("Comment", text: viewStore.$comment)
          }

        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Save") {
              viewStore.send(.onSaveTap)
            }
          }
        }
      }
    }
  }
}

