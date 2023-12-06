//
//  WidgetSelectorView.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

@_spi(Mock) import Common
import ComposableArchitecture
import Foundation
import SwiftUI
import WidgetUI

public struct WidgetSelectorView: View {
  public init(store: StoreOf<Sharing>) {
    self.store = store
  }

  let store: StoreOf<Sharing>
  @Namespace var animation

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        switch viewStore.currentWidgetType {
        case .systemMedium:
          NextRaceMediumWidgetView(
            race: viewStore.race,
            lastUpdatedDate: nil)
          .matchedAnimation(in: animation)
        case .systemLarge:
          NextRaceLargeWidgetView(
            race: viewStore.race,
            lastUpdatedDate: nil)
          .matchedAnimation(in: animation)
        }
      }
      .widgetBackground()
      .widgetFrame(family: viewStore.currentWidgetType.supportedFamily)
      .onTapGesture {
        withAnimation {
          _ = viewStore.send(.onWidgetTap)
        }
      }
    }
  }
}

private extension View {
  func matchedAnimation(in animation: Namespace.ID) -> some View {
    self
      .matchedGeometryEffect(id: "widget", in: animation)
  }
}

#Preview {
  var state = Sharing.State(race: .mock)
  let store = Store(initialState: state) {
    Sharing()
  }

  return ZStack {
    Color.black
    WidgetSelectorView(store: store)
  }
  .frame(maxWidth: .infinity, maxHeight: .infinity)
}
