//
//  SharingRenderableView.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

@_spi(Mock) import Common
import ComposableArchitecture
import Foundation
import SwiftUI

struct SharingRenderableView: View {

  let store: StoreOf<Sharing>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      ZStack {
        WidgetSelectorView(store: store)
        AppWatermark()
          .frame(maxHeight: .infinity, alignment: .bottom)
          .padding(.bottom, 25)

      }
      .padding()
      .background {
        SharingBackground()
        // TODO: Remove border radius when rendering
          .clipShape(RoundedRectangle(cornerRadius: viewStore.hasTappedShare ? 0.0 : 30.0, style: .continuous))
          .padding(viewStore.hasTappedShare ? 0 : 2)
          .onTapGesture {
            store.send(.onBackgroundTap)
          }
      }
    }
  }
}

#Preview("Instagram Renderable") {
  var state = Sharing.State(race: .mock, isSquareAspectRatio: true)
  state.hasTappedShare = true
  let store = Store(initialState: state) {
    Sharing()
  }

  return SharingRenderableView(store: store)
  .frame(height: 640)
  .background(.black)
}

#Preview("Square Renderable", traits: .fixedLayout(width: 360, height: 360)) {
  var state = Sharing.State(race: .mock, isSquareAspectRatio: true)
  state.hasTappedShare = true
  let store = Store(initialState: state) {
    Sharing()
  }

  return ZStack {
    Color.black.ignoresSafeArea()
    SharingRenderableView(store: store)
      .frame(height: 360)
  }

}


