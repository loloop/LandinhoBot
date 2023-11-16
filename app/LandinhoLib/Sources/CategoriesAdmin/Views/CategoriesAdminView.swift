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
            store.send(.onAppear)
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
              Button("Edit") {
                viewStore.send(.onCategoryEditorTap(category.id))
              }
            }

          }
        }
      }
    }
    .navigationTitle("Categories")
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
      store: store
        .scope(
          state: { $0.$categoryEditorState },
          action: CategoriesAdmin.Action.categoryEditor)) { store in
            CategoryEditorView(store: store)
          }
  }
}
