//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 15/11/23.
//

import APIClient
import ComposableArchitecture
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
        case .idle, .loading, .reloading:
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
    .background(Color(.secondarySystemBackground))
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
    .onAppear {
      store.send(.onAppear)
    }
    .sheet(
      store: store
        .scope(
          state: { $0.$raceEditorState },
          action: RacesAdmin.Action.raceEditor)) { store in
            RaceEditorView(store: store)
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
              Text("\(race.earliestEventDate?.formatted() ?? "")")
            }
            Spacer()
            Image(systemName: "chevron.right")
          }
        }
        .foregroundStyle(.primary)
        .contextMenu(menuItems: {
          Button("Edit") {
            store.send(.onEditTap(race))
          }
        })
      }
    }
  }

}