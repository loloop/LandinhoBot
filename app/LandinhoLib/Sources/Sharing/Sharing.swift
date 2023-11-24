//
//  Sharing.swift
//
//
//  Created by Mauricio Cardozo on 20/11/23.
//

import Common
import ComposableArchitecture
import Foundation
import UIKit

@Reducer
public struct Sharing {
  public init() {}

  public struct State: Equatable {
    public init(race: MegaRace) {
      self.race = race
    }

    let race: MegaRace
    var isSquareAspectRatio: Bool = true
    var currentWidgetType: ShareableWidgetType = .systemMedium
    var hasTappedShare: Bool = false
    var renderedImage: UIImage? = nil
    @BindingState var isSharing = false
  }

  public enum Action: Equatable, BindableAction {
    case onBackgroundTap
    case onWidgetTap
    case onShareTap
    case onDismissShare
    case toggleAspectRatio
    case onRender(UIImage)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onShareTap:
        state.hasTappedShare = true
        return .none
      case .onBackgroundTap:
        // TODO: If there's more than a single background for this category, go to the next one
        return .none
      case .onWidgetTap:
        state.currentWidgetType = ShareableWidgetType.allCases.next(element: state.currentWidgetType)
        return .none
      case .toggleAspectRatio:
        state.isSquareAspectRatio.toggle()
        return .none
      case .onRender(let image):
        state.renderedImage = image
        state.isSharing = true
        return .none
      case .onDismissShare:
        state.hasTappedShare = false
        return .none
      case .binding:
        return .none
      }
    }
  }
}

// This is not a general purpose extension
private extension Array where Element: Equatable {
  func next(element: Element) -> Element {
    guard 
      let idx = firstIndex(of: element)
    else {
      return element
    }

    let nextIdx = index(after: idx)
    if nextIdx < endIndex {
      return self[nextIdx]
    } else {
      return self[0]
    }
  }
}
