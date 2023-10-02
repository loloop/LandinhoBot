//
//  File.swift
//
//
//  Created by Mauricio Cardozo on 02/10/23.
//

import APIClient
import ComposableArchitecture
import Foundation
import SwiftUI

public struct Races: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(title: String, tag: String) {
      self.title = title
      self.tag = tag
    }

    let title: String
    let tag: String

    var raceList = APIClient<[Race]>.State(endpoint: "race")
    var removePastRacesState = APIClient<[Race]>.State(endpoint: "prune-race")

    @PresentationState var raceEditorState: RaceEditor.State?
  }

  public enum Action: Equatable {
    case onAppear
    case onPlusTap
    case onPruneTap

    case removePastRacesRequest(APIClient<[Race]>.Action)
    case raceRequest(APIClient<[Race]>.Action)
    case raceEditor(PresentationAction<RaceEditor.Action>)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onPlusTap:
        state.raceEditorState = .init(tag: state.tag)
        return .none

      case .onAppear:
        let tag = state.tag
        return .run { send in
          await send(.raceRequest(.request(.get(queryItems: [
            URLQueryItem(name: "tag", value: tag)
          ]))))
        }

      case .onPruneTap:
        let tag = state.tag
        return .run { send in
          await send(.removePastRacesRequest(.request(.get(queryItems: [
            .init(name: "tag", value: tag)
          ]))))
        }

      case .raceEditor(.presented(.raceRequest(.response(.finished(.success))))):
        return .merge(
          .send(.onAppear),
          .send(.raceEditor(.dismiss))
        )

      case .removePastRacesRequest(.response(.finished(.success(let races)))):
        state.raceList.response = .finished(.success(races))
        return .none

      case .raceRequest, .raceEditor, .removePastRacesRequest:
        return .none
      }
    }.ifLet(\.$raceEditorState, action: /Action.raceEditor) {
      RaceEditor()
    }

    Scope(state: \.raceList, action: /Action.raceRequest) {
      APIClient()
    }

    Scope(state: \.removePastRacesState, action: /Action.removePastRacesRequest) {
      APIClient()
    }
  }

  public struct Race: Codable, Equatable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let earliestEventDate: Date
  }
}

import APIRequester
public struct RaceListView: View {
  public init(store: StoreOf<Races>) {
    self.store = store
  }

  let store: StoreOf<Races>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Group {
        switch viewStore.raceList.response {
        case .idle, .loading, .reloading:
          ProgressView()
        case .finished(.failure(let error)):
          ContentUnavailableView(
            "Something went wrong",
            systemImage: "xmark.octagon",
            description: Text((error as? APIError)?.jsonString ?? ""))
        case .finished(.success(let races)):
          if races.isEmpty {
            ContentUnavailableView(
              "This category has no races",
              systemImage: "magnifyingglass")
          } else {
            List {
              ForEach(races) { race in
                NavigationLink(state: link(to: race)) {
                  HStack {
                    VStack(alignment: .leading) {
                      Text(race.title)
                        .font(.title3)
                      Text("\(race.earliestEventDate.formatted())")
                    }
                  }
                }
              }
            }
          }
        }
      }
      .navigationTitle(viewStore.title)
      .navigationBarTitleDisplayMode(.large)
    }
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
          action: Races.Action.raceEditor)) { store in
            RaceEditorView(store: store)
          }
  }

  func link(to: Races.Race) -> Categories.Path.State {
    Categories.Path.State.events(.init(id: to.id, title: to.title))
  }
}


public struct RaceEditor: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(race: Races.Race, tag: String) {
      id = race.id
      title = race.title
      isEditing = true
      self.tag = tag
    }

    public init(tag: String) {
      self.tag = tag
      id = ""
      title = ""
      isEditing = false
    }

    let id: String
    let tag: String
    @BindingState var title: String
    @BindingState var date = Date()

    let isEditing: Bool
    var raceAPI = APIClient<Races.Race>.State(endpoint: "race")

    var isSaveInactive: Bool {
      title.isEmpty
    }
  }

  public enum Action: Equatable, BindableAction {
    case onSaveTap
    case raceRequest(APIClient<Races.Race>.Action)
    case binding(BindingAction<State>)
  }

  public var body: some ReducerOf<Self> {
    BindingReducer()

    Reduce { state, action in
      switch action {
      case .onSaveTap:
        if state.isEditing {
          return .none
//          let request = Races.Race(id: state.id, title: state.title)
//          return .run { send in
//            try await send(.raceRequest(.request(.patch(request))))
//          }
        } else {
          let request = UploadRaceRequest(
            title: state.title,
            categoryTag: state.tag,
            earliestEventDate: state.date)
          return .run { send in
            try await send(.raceRequest(.request(.post(request))))
          }
        }

      case .binding, .raceRequest:
        return .none
      }
    }

    Scope(state: \.raceAPI, action: /Action.raceRequest) {
      APIClient()
    }
  }

  public struct UploadRaceRequest: Codable, Equatable {
    let title: String
    let categoryTag: String
    let earliestEventDate: Date
  }
}

public struct RaceEditorView: View {
  public init(store: StoreOf<RaceEditor>) {
    self.store = store
  }

  let store: StoreOf<RaceEditor>

  public var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      NavigationStack {
        List {
          HStack {
            Text("Title")
            TextField("Title", text: viewStore.$title)
          }
          HStack {
            DatePicker("Date", selection: viewStore.$date)
              .datePickerStyle(.graphical)
          }
        }
        .toolbar {
          ToolbarItem(placement: .primaryAction) {
            Button("Save") {
              viewStore.send(.onSaveTap)
            }
            .disabled(viewStore.isSaveInactive)
          }
        }
      }
    }
  }
}

