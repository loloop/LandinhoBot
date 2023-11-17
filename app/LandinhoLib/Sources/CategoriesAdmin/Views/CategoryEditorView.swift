//
//  CategoryEditorView.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

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
            Text("Título")
            TextField("Título", text: viewStore.$title)
          }
          HStack {
            Text("Tag")
            TextField("Tag", text: viewStore.$tag)
          }
          VStack(alignment: .leading) {
            Text("Comentário")
            TextField("Comentário", text: viewStore.$comment, axis: .vertical)
          }

        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Salvar") {
              viewStore.send(.onSaveTap)
            }
          }
        }
      }
    }
  }
}

#Preview {
  CategoryEditorView(store: .init(initialState: .init(), reducer: {
    CategoryEditor()
  }))
}
