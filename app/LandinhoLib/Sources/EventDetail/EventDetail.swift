//
//  EventDetail.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

@_spi(Mock) import Common
import Foundation
import ComposableArchitecture
import SwiftUI

public struct EventDetail: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(raceID: UUID) {
      self.raceID = raceID
      self.race = nil
    }

    public init(race: Race) {
      self.raceID = nil
      self.race = race
    }

    let raceID: UUID?
    let race: Race?
  }

  public enum Action: Equatable {
    case onAppear
    case delegate(DelegateAction)
  }

  public enum DelegateAction: Equatable {
    case onShareTap(race: Race)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear:
        // TODO: Fetch from raceID if race is nil
        return .none
      case .delegate:
        return .none
      }
    }
  }
}

public struct EventDetailView: View {
  public init(store: StoreOf<EventDetail>) {
    self.store = store
  }

  let store: StoreOf<EventDetail>

  public var body: some View {
    Group {
      WithViewStore(store, observe: { $0 }) { viewStore in
        if let race = viewStore.race {
          InnerEventDetailView(store: store, race: race)
        } else {
          ContentUnavailableView(
            "Algo de errado aconteceu",
            systemImage: "xmark.octagon",
            description: Text("Tipo deu ruim MESMO porque ainda não tá pronto"))
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      .background.secondary
    )
  }
}

struct InnerEventDetailView: View {
  let store: StoreOf<EventDetail>
  let race: Race

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {

        MainEventsView(events: mainEvents)

        RoundedRectangle(cornerRadius: 25.0, style: .continuous)
          .frame(height: 200)
          .overlay {
            // TODO: Track SVG, Apple Map or whatever here
            Text("Placeholder - Mapa de pista")
              .foregroundStyle(.primary)
              .colorInvert()
          }

        VStack(alignment: .leading) {
          Text("Título Completo")
            .font(.caption)
          Text(race.title)
            .font(.title3)
        }

        VStack(alignment: .leading) {
          Text("Eventos")
            .font(.title2)

          Spacer()

          VStack(alignment: .leading) {
            ForEach(eventsByDate) { event in
              Text(event.date)
                .font(.headline)
              ForEach(event.events) { innerEvent in
                HStack {
                  Text(innerEvent.title)
                    .font(.title3)

                  Spacer()
                  Text(innerEvent.time)
                    .fontDesign(.monospaced)
                }
              }
              Spacer()
            }

            Text("Todos os horários estão no fuso horário do Brasil")
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .trailing)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .frame(maxWidth: .infinity)
    .navigationTitle(race.shortTitle)
    .toolbar {
      ToolbarItem {
        Button("Compartilhar", systemImage: "square.and.arrow.up") {
          store.send(.delegate(.onShareTap(race: race)))
        }
      }
    }
  }

  var mainEvents: [RaceEvent] {
    race.events.filter { $0.isMainEvent }
  }

  var eventsByDate: [EventByDate] {
    EventByDateFactory.convert(events: race.events)
  }
}

struct MainEventsView: View {

  let events: [RaceEvent]

  var body: some View {
    if events.count <= 2 {
      singleEventView
    } else {
      multipleEventsView
    }
  }

  var singleEventView: some View {
    VStack(alignment: .leading) {
      ForEach(events) { event in
        HStack {
          Text(event.title)
            .font(.title)
            .scaledToFit()
            .minimumScaleFactor(0.01)

          Spacer()

          VStack(alignment: .trailing) {
            Text(event.date.formatted(.dateTime.day().weekday()))
              .font(.caption)
            Text(event.date.formatted(.dateTime.hour().minute()))
              .font(.title)
          }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15.0, style: .continuous))
        .shadow(color: .black.opacity(0.1), radius: 1)
      }
    }
  }

  var multipleEventsView: some View {
    ScrollView(.horizontal) {
      HStack {
        ForEach(events) { event in
          VStack {
            Text(event.title)
              .font(.title2)
            Spacer()

            Text(event.date.formatted(.dateTime.day().weekday()))
              .font(.caption)
            Text(event.date.formatted(.dateTime.hour().minute()))
              .font(.title)
          }
          .padding()
          .padding(.horizontal)
          .background(Color(.systemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 10.0, style: .continuous))
          .shadow(color: .black.opacity(0.1), radius: 1)
        }
      }
    }
    .scrollClipDisabled()
    .scrollIndicators(.hidden, axes: .horizontal)
  }
}

#Preview {
  NavigationStack {
    EventDetailView(store: .init(initialState: .init(race: .mock), reducer: {
      EventDetail()
    }))
  }
}
