//
//  EventDetail.swift
//
//
//  Created by Mauricio Cardozo on 12/11/23.
//

@_spi(Mock) import LandinhoFoundation
import CategoryUI
import Foundation
import ComposableArchitecture
@_spi(Internal) import APIClient
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

    public let raceID: UUID?
    public var race: Race?
    public var isLoading = false
    public var loadFailure: LoadFailure?
  }

  public enum Action: Equatable {
    case onAppear
    case retry
    case onDisappear
    case response(TaskResult<Race>)
    case delegate(DelegateAction)
  }

  public enum LoadFailure: Equatable {
    case notFound
    case unavailable
  }

  @Dependency(\.apiRequester) var apiRequester
  private enum CancelID { case roundRequest }

  public enum DelegateAction: Equatable {
    case onShareTap(race: Race)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear, .retry:
        guard let id = state.raceID, state.race == nil, !state.isLoading else { return .none }
        if action == .onAppear, state.loadFailure != nil { return .none }
        state.isLoading = true
        state.loadFailure = nil
        return .run { send in
          do {
            let race = try await apiRequester.request(Race.self,
              endpoint: "rounds/\(id.uuidString.lowercased())", method: "GET", data: nil,
              queryItems: [], headers: [:])
            try Task.checkCancellation()
            await send(.response(.success(race)))
          } catch {
            guard !Task.isCancelled, !(error is CancellationError) else { return }
            await send(.response(.failure(error)))
          }
        }
        .cancellable(id: CancelID.roundRequest, cancelInFlight: true)

      case .onDisappear:
        state.isLoading = false
        return .cancel(id: CancelID.roundRequest)

      case .response(.success(let race)):
        guard state.isLoading else { return .none }
        state.isLoading = false
        guard race.id == state.raceID else {
          state.loadFailure = .unavailable
          return .none
        }
        state.race = race
        return .none

      case .response(.failure(let error)):
        guard state.isLoading else { return .none }
        state.isLoading = false
        let error = error as NSError
        state.loadFailure = error.domain == "LandinhoAPI" && error.code == 404 ? .notFound : .unavailable
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
        } else if let failure = viewStore.loadFailure {
          ContentUnavailableView {
            Label(failure == .notFound ? "Rodada não encontrada" : "Não foi possível carregar a rodada",
              systemImage: "flag.slash")
          } description: {
            Text(failure == .notFound ? "O link pode apontar para uma rodada removida." : "Confira sua conexão e tente novamente.")
          } actions: {
            Button("Tentar novamente") { viewStore.send(.retry) }
              .buttonStyle(.bordered)
          }
        } else {
          ProgressView("Carregando rodada…")
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(
      .background.secondary
    )
    .task { store.send(.onAppear) }
    .onDisappear { store.send(.onDisappear) }
  }
}

struct InnerEventDetailView: View {
  let store: StoreOf<EventDetail>
  let race: Race

  var body: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        CategoryNameLabel(category: race.category)
          .font(.headline)

        if race.events.isEmpty || race.events.contains(where: { $0.date == nil && !$0.isCancelled }) {
          Text("Ainda não conseguimos obter todos os horários. Consulte a fonte oficial para confirmar a programação.")
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        if let source = race.sourceURL, let url = URL(string: source) {
          Link("Ver programação oficial", destination: url)
        }

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

            Text("Horários no fuso do seu dispositivo")
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
        Menu {
          ShareLink(item: race.roundLinkShareText) {
            Label("Compartilhar link", systemImage: "link")
          }
          Button("Compartilhar imagem", systemImage: "photo") {
            store.send(.delegate(.onShareTap(race: race)))
          }
        } label: {
          Label("Compartilhar", systemImage: "square.and.arrow.up")
        }
      }
    }
    .categoryAccent(race.category.resolvedColor)
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
            Text(event.dayLabel)
              .font(.caption)
            Text(event.timeLabel)
              .font(.title)
          }
        }
        .padding()
        // FIXME: Color not available on tvOS
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

            Text(event.dayLabel)
              .font(.caption)
            Text(event.timeLabel)
              .font(.title)
          }
          .padding()
          .padding(.horizontal)
          // FIXME: Color not available on tvOS
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
