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
          VStack(alignment: .leading) {
            Text("Título")
            TextField("Título", text: viewStore.$title)
          }
          VStack(alignment: .leading) {
            Text("Título Curto")
            TextField("Título curto", text: viewStore.$shortTitle)
          }
          HStack {
            DatePicker("Date", selection: viewStore.$date)
              .datePickerStyle(.graphical)
          }
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Salvar") {
              viewStore.send(.onSaveTap)
            }
            .disabled(viewStore.isSaveInactive)
          }
        }
      }
    }
  }
}

#Preview {
  NavigationStack {
    RaceEditorView(store: .init(initialState: .init(tag: "tag"), reducer: {
      RaceEditor()
    }))
  }
}
