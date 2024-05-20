//
//  NotificationQueue.swift
//
//
//  Created by Mauricio Cardozo on 14/08/23.
//

import Foundation
import ComposableArchitecture

@Reducer
public struct NotificationsQueue {
  @_spi(Internal) public init() {}
  public struct State: Equatable {
    @_spi(Internal) public init() {}

    var currentErrors: [QueueableNotification] = []
  }

  public enum Action: Equatable {
    case observeNotifications
    case presentNotification(QueueableNotification)
    case handleNotification(QueueableNotification)
  }

  @Dependency(\.notificationQueue) var notificationQueue

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .observeNotifications:
        return .run { send in
          for await notif in notificationQueue.observer {
            await send(.presentNotification(notif))
          }
        }
      case .presentNotification(let id):
        state.currentErrors.append(id)
        return .none
      case .handleNotification(let id):
        state.currentErrors.removeAll(where: { $0 == id })
        return .none
      }
    }
  }
}

import SwiftUI
@_spi(Internal) public struct NotificationsQueueView: View {
  public init(store: StoreOf<NotificationsQueue>) {
    self.store = store
  }

  let store: StoreOf<NotificationsQueue>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Color.clear.overlay(alignment: .top) {
        VStack {
          ForEach(viewStore.currentErrors) { error in
            NotificationContainerView(error: error) {
              viewStore.send(.handleNotification(error), animation: .smooth)
            }
          }
        }
      }
    }
  }
}
