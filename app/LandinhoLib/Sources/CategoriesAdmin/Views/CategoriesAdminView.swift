//
//  CategoryListView.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI
import RacesAdmin

public struct CategoriesAdminView: View {
  public init(store: StoreOf<CategoriesAdmin>) {
    self.store = store
  }

  let store: StoreOf<CategoriesAdmin>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      switch viewStore.categoryList.response {
      case .idle:
        Color(.systemBackground)
          .opacity(0.01)
          .onAppear {
            viewStore.send(.onAppear)
          }
      case .loading, .reloading:
        ProgressView()
      case .finished(.failure(let error)):
        APIErrorView(error: error)
      case .finished(.success(let categories)):
        // TODO: Move to `Events` approach with Bindings
        List {
          ForEach(categories) { category in
            Button {
              viewStore.send(.onCategoryTap(category.id))
            } label: {
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
                Image(systemName: "chevron.right")
              }
            }
            .foregroundStyle(.primary)
            .contextMenu {
              Button("Editar") {
                viewStore.send(.onCategoryEditorTap(category.id))
              }
            }

          }
        }
      }
    }
    .navigationTitle("Categorias")
    .navigationBarTitleDisplayMode(.large)
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
      store: store.scope(state: \.$destination, action: { .destination($0) }),
      state: \.categoryEditor,
      action: { .categoryEditor($0) }
    ) { store in
      CategoryEditorView(store: store)
    }
    .navigationDestination(
      store: store.scope(state: \.$destination, action: { .destination($0) }),
      state: \.racesAdmin,
      action: { .racesAdmin($0) }
    ) { store in
      RacesAdminView(store: store)
    }
  }
}

#Preview {
  NavigationStack {
    CategoriesAdminView(store: .init(initialState: .init(), reducer: {
      CategoriesAdmin()
    }))
  }
}
