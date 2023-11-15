//
//  EventsAdminView.swift
//
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI

public struct EventsAdminView: View {
  public init(store: StoreOf<EventsAdmin>) {
    self.store = store
  }

  let store: StoreOf<EventsAdmin>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        switch viewStore.eventList.response {
        case .idle, .loading, .reloading:
          ProgressView()
        case .finished(.failure(let error)):
          APIErrorView(error: error)
        case .finished(.success):
          if viewStore.events.isEmpty {
            emptyList
          } else {
            eventsList(with: viewStore)
          }
        }
      }
      .navigationTitle(viewStore.title)
      .toolbarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .secondaryAction) {
          Button("Add F1 Weekend") {
            viewStore.send(.addBundle(.F1Regular))
          }
        }

        ToolbarItem(placement: .secondaryAction) {
          Button("Add F1 Sprint Weekend") {
            viewStore.send(.addBundle(.F1Sprint))
          }
        }

        ToolbarItem {
          Button("Save") {
            viewStore.send(.saveList)
          }
          .disabled(viewStore.hasEditedEventList)
        }
      }
    }
    .onAppear {
      store.send(.onAppear)
    }
  }

  @MainActor
  var emptyList: some View {
    ContentUnavailableView(label: {
      Label("This race has no events", systemImage: "magnifyingglass")
    }, actions: {
      Button("Add event") {
        store.send(.addEvent)
      }
    })
  }

  @MainActor
  func eventsList(with viewStore: ViewStoreOf<EventsAdmin>) -> some View {
    VStack {
      List(viewStore.$events, editActions: .all) { event in
        VStack {
          HStack {
            Text("Title")
            TextField("Title", text: event.title)
          }
          DatePicker("Date", selection: event.date)
        }
      }
      // TODO: This button is on a really bad position, please make it better
      Button("Add event") {
        viewStore.send(.addEvent)
      }
    }
  }
}


