//
//  RacesAdmin.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import APIClient
import Common
import ComposableArchitecture
import EventsAdmin
import Foundation
import SwiftUI

extension RacesAdmin {
  @Reducer
  public struct Destination {
    public init() {}

    public enum State: Equatable {
      case raceEditor(RaceEditor.State)
      case eventsAdmin(EventsAdmin.State)
    }

    public enum Action: Equatable {
      case raceEditor(RaceEditor.Action)
      case eventsAdmin(EventsAdmin.Action)
    }

    public var body: some ReducerOf<Self> {
      Scope(state: \.raceEditor, action: \.raceEditor) {
        RaceEditor()
      }

      Scope(state: \.eventsAdmin, action: \.eventsAdmin) {
        EventsAdmin()
      }
    }
  }
}


@Reducer
public struct RacesAdmin {
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

    @PresentationState var destination: Destination.State?
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
    case destination(PresentationAction<Destination.Action>)
  }

  @Dependency(\.notificationQueue) var notificationQueue

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onPlusTap:
        state.destination = .raceEditor(.init(tag: state.tag))
        return .none

      case .onAppear:
        let tag = state.tag
        return .run { send in
          await send(.raceRequest(.request(.get(queryItems: [
            URLQueryItem(name: "tag", value: tag)
          ]))))
        }

      case .onEditTap(let race):
        state.destination = .raceEditor(.init(race: race, tag: state.tag))
        return .none

      case .onRaceTap(let race):
        state.destination = .eventsAdmin(.init(id: race.id, title: race.title))
        return .send(.destination(.presented(.eventsAdmin(.onAppear))))

      case .onPruneTap:
        let tag = state.tag
        return .run { send in
          await send(.removePastRacesRequest(.request(.get(queryItems: [
            .init(name: "tag", value: tag)
          ]))))
        }

      case .destination(.presented(.raceEditor(.raceRequest(.response(.finished(.success)))))):
        return .merge(
          .send(.onAppear),
          .send(.destination(.dismiss))
        )

      case .destination(.presented(.raceEditor(.raceRequest(.response(.finished(.failure(let error))))))):
        notificationQueue.enqueue(.critical((error as NSError).localizedDescription))
        return .none

      case .removePastRacesRequest(.response(.finished(.success(let races)))):
        state.raceList.response = .finished(.success(races))
        return .none

      case .raceRequest, .destination, .removePastRacesRequest:
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
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

