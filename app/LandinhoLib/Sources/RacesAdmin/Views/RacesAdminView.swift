//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import APIClient
import ComposableArchitecture
import EventsAdmin
import Foundation
import SwiftUI

public struct RacesAdminView: View {
  public init(store: StoreOf<RacesAdmin>) {
    self.store = store
  }

  let store: StoreOf<RacesAdmin>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        switch viewStore.raceList.response {
        case .idle:
          Color(.secondarySystemBackground)
            .onAppear {
              viewStore.send(.onAppear)
            }
        case .loading, .reloading:
          ProgressView()
        case .finished(.failure(let error)):
          APIErrorView(error: error)
        case .finished(.success(let races)):
          if races.isEmpty {
            ContentUnavailableView(
              "This category has no races",
              systemImage: "magnifyingglass")
          } else {
            list(from: races)
          }
        }
      }
      .navigationTitle(viewStore.title)
      .navigationBarTitleDisplayMode(.large)
    }
    .background(.background.secondary)
    .toolbar {
      ToolbarItem(placement: .secondaryAction) {
        Button(action: {
          store.send(.onPruneTap)
        }, label: {
          Text("Remove past races")
        })
      }

      ToolbarItem {
        Button(action: {
          store.send(.onPlusTap)
        }, label: {
          Image(systemName: "plus")
        })
      }
    }
    .sheet(
      store: store.scope(state: \.$destination, action: { .destination($0) }),
      state: \.raceEditor,
      action: { .raceEditor($0) }
    ) { store in
      RaceEditorView(store: store)
    }
    .navigationDestination(
      store: store.scope(state: \.$destination, action: { .destination($0) }),
      state: \.eventsAdmin,
      action: { .eventsAdmin($0) }
    ) { store in
      EventsAdminView(store: store)
    }
  }

  @MainActor
  func list(from races: [RacesAdmin.Race]) -> some View {
    // TODO: Move to `Events` approach with Bindings
    List {
      ForEach(races) { race in
        Button {
          store.send(.onRaceTap(race))
        } label: {
          HStack {
            VStack(alignment: .leading) {
              Text(race.title)
                .font(.title3)
              Text(race.shortTitle)
                .font(.headline)
              Text("\(race.earliestEventDate?.formatted() ?? "")")
                .font(.subheadline)
            }
            Spacer()
            Image(systemName: "chevron.right")
          }
        }
        .foregroundStyle(.primary)
        .contextMenu(menuItems: {
          Button("Editar") {
            store.send(.onEditTap(race))
          }
        })
      }
    }
  }

}
