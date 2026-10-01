//
//  CategoryEditorView.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import ComposableArchitecture
import CategoryUI
import Foundation
import LandinhoFoundation
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
          Section {
            ColorPicker("Escolher cor", selection: viewStore.binding(
              get: { $0.resolvedColor.swiftUIColor },
              send: { .binding(.set(\.$color, categoryColor(from: $0))) }
            ), supportsOpacity: false)

            HStack(spacing: 12) {
              CategoryColorSwatch(color: viewStore.resolvedColor, size: 32)
                .accessibilityHidden(true)
              VStack(alignment: .leading) {
                Text(viewStore.title.isEmpty ? "Prévia da categoria" : viewStore.title)
                  .font(.headline)
                Text(viewStore.resolvedColor.hex)
                  .font(.caption.monospaced())
                  .foregroundStyle(.secondary)
              }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Prévia da cor da categoria")
            .accessibilityValue(viewStore.resolvedColor.hex)

            Button("Usar cor automática") {
              viewStore.send(.binding(.set(\.$color, nil)))
            }
            .disabled(viewStore.color == nil)
          } header: {
            Text("Cor da categoria")
          } footer: {
            Text("A cor identifica a categoria. Sem uma escolha, usamos uma cor automática baseada na tag.")
          }
        }
        .navigationTitle(viewStore.isEditing ? "Editar categoria" : "Nova categoria")
        .navigationBarTitleDisplayMode(.inline)
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

  private func categoryColor(from color: Color) -> CategoryColor? {
    guard let space = CGColorSpace(name: CGColorSpace.sRGB),
      let rgb = UIColor(color).cgColor.converted(to: space, intent: .defaultIntent, options: nil),
      let components = rgb.components, components.count >= 3
    else { return nil }
    func byte(_ component: CGFloat) -> UInt8 {
      UInt8((min(max(component, 0), 1) * 255).rounded())
    }
    return CategoryColor(red: byte(components[0]), green: byte(components[1]), blue: byte(components[2]))
  }
}

#Preview {
  CategoryEditorView(store: .init(initialState: .init(), reducer: {
    CategoryEditor()
  }))
}
