//
//  ContentView.swift
//  VroomVroomTV
//
//  Created by Mauricio Cardozo on 20/05/24.
//

import ComposableArchitecture
import SwiftUI
@_spi(Internal) import NotificationsQueue
import ScheduleList

// TODO: Actually make this usable

struct ContentView: View {

  let store: StoreOf<Root>
  @EnvironmentObject var sceneDelegate: VroomSceneDelegate

    var body: some View {
        VStack {
          ScheduleListView(store: store.scope(state: \.scheduleListState, action: \.scheduleList))
          Button(action: {
            store.send(.onTap)
          }, label: {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
          })
        }
        .padding()
        .task {
          sceneDelegate.setupNotificationQueueWindow(with: store)
          store.send(.onAppear)
        }
    }
}

@Reducer
struct Root {
  public init() {}

  struct State: Equatable {
    var notificationQueueState = NotificationsQueue.State()
    var scheduleListState = ScheduleList.State(categoryTag: nil)
  }

  enum Action: Equatable {
    case onAppear
    case onTap

    case notificationQueue(NotificationsQueue.Action)
    case scheduleList(ScheduleList.Action)
  }

  @Dependency(\.notificationQueue) var notificationQueue

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:

        return .send(.notificationQueue(.observeNotifications))

      case .onTap:
        notificationQueue.enqueue(.success("lmao"))
        return .none

      case .notificationQueue, .scheduleList:
        return .none
      }
    }

    Scope(state: \.notificationQueueState, action: \.notificationQueue) {
      NotificationsQueue()
    }

    Scope(state: \.scheduleListState, action: \.scheduleList) {
      ScheduleList()
    }
  }
}
