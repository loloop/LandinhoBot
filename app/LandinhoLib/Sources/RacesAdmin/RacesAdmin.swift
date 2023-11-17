//
//  RacesAdmin.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import APIClient
import Common
import ComposableArchitecture
import Foundation
import SwiftUI

import EventsAdmin

public struct RacesAdmin: Reducer {
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
    // TODO: Add a DelegateAction
    case onEditTap(Race)
    case onRaceTap(Race)

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

      case .onEditTap(let race):
        state.raceEditorState = .init(race: race, tag: state.tag)
        return .none

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

      case .raceEditor(.presented(.raceRequest(.response(.finished(.failure(let error)))))):
        print(error)
        return .none

      case .removePastRacesRequest(.response(.finished(.success(let races)))):
        state.raceList.response = .finished(.success(races))
        return .none

      case .raceRequest, .raceEditor, .removePastRacesRequest, .onRaceTap:
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
    public let shortTitle: String
    public let earliestEventDate: Date?
  }
}

