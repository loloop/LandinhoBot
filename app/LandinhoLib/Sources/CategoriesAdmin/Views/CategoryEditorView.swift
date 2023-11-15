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
