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
        ToolbarItemGroup(placement: .secondaryAction) {
          ForEach(UploadRaceEventBundle.allCases) { item in
            Button("Adicionar \(item.title)") {
              viewStore.send(.addBundle(item))
            }
          }
        }

        ToolbarItem {
          Button("Salvar") {
            viewStore.send(.saveList)
          }
          .disabled(viewStore.hasEditedEventList)
        }
      }
    }
  }

  @MainActor
  var emptyList: some View {
    ContentUnavailableView(label: {
      Label("Esta corrida não tem eventos", systemImage: "magnifyingglass")
    }, actions: {
      Button("Adicionar evento") {
        store.send(.addEvent)
      }
    })
  }

  @MainActor
  func eventsList(with viewStore: ViewStoreOf<EventsAdmin>) -> some View {
    Form {
      Section {
        List(viewStore.$events, editActions: .all) { event in
          VStack {
            HStack {
              Text("Título")
              TextField("Título", text: event.title)
            }
            HStack {
              Toggle(isOn: event.isMainEvent, label: {
                Text("É evento principal?")
              })
            }
            DatePicker("Data", selection: event.date)
          }
        }
      } footer: {
        Button("Adicionar evento") {
          viewStore.send(.addEvent)
        }
      }
    }
  }
}


#Preview {
  var state = EventsAdmin.State(id: "", title: "Spa Francorchamps")
  state.eventList.response = .finished(.success([]))
  state.events = [
    .init(title: "", date: Date(), isMainEvent: false),
    .init(title: "", date: Date(), isMainEvent: false),
  ]

  return NavigationStack {
    EventsAdminView(store: .init(initialState: state, reducer: {
      EventsAdmin()
    }))
  }
}
