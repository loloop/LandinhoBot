//
//  SharingRenderableView.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

@_spi(Mock) import LandinhoFoundation
import ComposableArchitecture
import Foundation
import SwiftUI

struct SharingRenderableView: View {

  let store: StoreOf<Sharing>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      GeometryReader { geometry in
        let widgetSize = viewStore.currentWidgetType.size
        // Reserve the watermark's 30-point height, spacing, and outer padding.
        let widgetScale = max(0, min(
          1,
          (geometry.size.width - 32) / widgetSize.width,
          (geometry.size.height - 83) / widgetSize.height))

        VStack(spacing: 12) {
          WidgetSelectorView(store: store)
            .scaleEffect(widgetScale)
            .frame(
              width: widgetSize.width * widgetScale,
              height: widgetSize.height * widgetScale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

          AppWatermark()
            .foregroundStyle(.white)
        }
        .padding(16)
        .padding(.bottom, 9)
      }
      .background {
        SharingBackground()
          .clipShape(RoundedRectangle(cornerRadius: viewStore.hasTappedShare ? 0.0 : 30.0, style: .continuous))
          .padding(viewStore.hasTappedShare ? 0 : 2)
          .onTapGesture {
            store.send(.onBackgroundTap)
          }
      }
    }
  }
}

#Preview("16/9 Renderable") {
  var state = Sharing.State(race: .mock)
  state.hasTappedShare = true
  let store = Store(initialState: state) {
    Sharing()
  }

  return SharingRenderableView(store: store)
  .frame(height: 640)
  .background(.black)
}

#Preview("Square Renderable", traits: .fixedLayout(width: 360, height: 360)) {
  var state = Sharing.State(race: .mock)
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

