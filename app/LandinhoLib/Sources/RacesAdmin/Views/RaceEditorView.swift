//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI

public struct RaceEditorView: View {
  public init(store: StoreOf<RaceEditor>) {
    self.store = store
  }

  let store: StoreOf<RaceEditor>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        List {
          HStack {
            Text("Title")
            TextField("Title", text: viewStore.$title)
          }
          HStack {
            DatePicker("Date", selection: viewStore.$date)
              .datePickerStyle(.graphical)
          }
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Save") {
              viewStore.send(.onSaveTap)
            }
            .disabled(viewStore.isSaveInactive)
          }
        }
      }
    }
  }
}

