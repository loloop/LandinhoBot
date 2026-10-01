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
import SessionReminders

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
    var reminders = SessionReminderSnapshot(authorization: .notDetermined, scheduledDates: [:])
    var isLoadingReminders = false
    var changingReminderID: UUID?
    var reminderError: String?
    var isNotificationSettingsNeeded = false
  }

  public enum Action: Equatable {
    case onAppear
    case retry
    case onDisappear
    case response(TaskResult<Race>)
    case refreshReminders
    case toggleReminder(UUID)
    case reminderResponse(TaskResult<SessionReminderSnapshot>)
    case reminderState(SessionReminderSnapshot)
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

  @Dependency(\.sessionReminders) var sessionReminders

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .onAppear, .retry:
        if state.race != nil { return .send(.refreshReminders) }
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
        return .send(.refreshReminders)

      case .response(.failure(let error)):
        guard state.isLoading else { return .none }
        state.isLoading = false
        let error = error as NSError
        state.loadFailure = error.domain == "LandinhoAPI" && error.code == 404 ? .notFound : .unavailable
        return .none

      case .refreshReminders:
        guard let race = state.race, !state.isLoadingReminders, state.changingReminderID == nil else { return .none }
        state.isLoadingReminders = true
        return .run { send in
          await send(.reminderResponse(TaskResult { try await sessionReminders.refresh([race]) }))
        }

      case .toggleReminder(let id):
        guard let race = state.race, let session = race.events.first(where: { $0.id == id }),
          !state.isLoadingReminders, state.changingReminderID == nil else { return .none }
        state.changingReminderID = id
        state.reminderError = nil
        state.isNotificationSettingsNeeded = false
        return .run { send in
          await send(.reminderResponse(TaskResult { try await sessionReminders.toggle(race, session) }))
        }

      case .reminderResponse(.success(let snapshot)):
        state.reminders = snapshot
        state.isLoadingReminders = false
        state.changingReminderID = nil
        state.reminderError = nil
        state.isNotificationSettingsNeeded = snapshot.authorization == .denied
        return .none

      case .reminderResponse(.failure(let error)):
        state.isLoadingReminders = true
        state.changingReminderID = nil
        state.isNotificationSettingsNeeded = (error as? SessionReminderError) == .permissionDenied
        switch error as? SessionReminderError {
        case .cancelled: state.reminderError = "Esta sessão foi cancelada."
        case .pendingTime: state.reminderError = "O horário desta sessão ainda não foi confirmado."
        case .alreadyStarted: state.reminderError = "Esta sessão já começou. Escolha uma sessão futura."
        case .permissionDenied: state.reminderError = "Permita notificações nos Ajustes para receber este lembrete."
        case .limitReached: state.reminderError = "Você atingiu o limite de lembretes. Desative um lembrete antes de adicionar outro."
        default: state.reminderError = "Não foi possível atualizar o lembrete. Tente novamente."
        }
        return .run { send in
          await send(.reminderState(await sessionReminders.current()))
        }

      case .reminderState(let snapshot):
        state.reminders = snapshot
        state.isLoadingReminders = false
        state.isNotificationSettingsNeeded = snapshot.authorization == .denied
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
  @Environment(\.scenePhase) var scenePhase
  @Environment(\.openURL) var openURL

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
                VStack(alignment: .leading, spacing: 8) {
                  HStack {
                    Text(innerEvent.title)
                      .font(.title3)
                    Spacer()
                    Text(innerEvent.time)
                      .fontDesign(.monospaced)
                  }
                  if let session = race.events.first(where: { $0.id == innerEvent.id }) {
                    SessionReminderButton(store: store, round: race, session: session)
                  }
                }
                .padding(.vertical, 6)
              }
              Spacer()
            }

            Text("Horários no fuso do seu dispositivo")
              .font(.caption)
              .foregroundStyle(.secondary)
              .frame(maxWidth: .infinity, alignment: .trailing)

            WithViewStore(store, observe: { $0 }) { viewStore in
              if let error = viewStore.reminderError {
                Text(error)
                  .font(.callout)
                  .foregroundStyle(.red)
                  .accessibilityLabel("Erro no lembrete: \(error)")
              }
              if viewStore.isNotificationSettingsNeeded {
                Text("As notificações estão desativadas para este app.")
                  .font(.callout)
                  .foregroundStyle(.secondary)
                #if os(iOS)
                Button("Abrir Ajustes de notificações") {
                  if let url = URL(string: UIApplication.openNotificationSettingsURLString) { openURL(url) }
                }
                #endif
              }
            }
            Text("Lembretes neste dispositivo, no início da sessão. Horários alterados são atualizados quando a programação é recarregada no app.")
              .font(.caption)
              .foregroundStyle(.secondary)
          }
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
    }
    .frame(maxWidth: .infinity)
    .navigationTitle(race.shortTitle)
    .onChange(of: scenePhase) { _, phase in
      if phase == .active { store.send(.refreshReminders) }
    }
    .toolbar {
      ToolbarItem {
        RoundShareMenu(race: race) {
          store.send(.delegate(.onShareTap(race: race)))
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

private struct SessionReminderButton: View {
  let store: StoreOf<EventDetail>
  let round: Race
  let session: RaceEvent

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      TimelineView(.periodic(from: .now, by: 30)) { context in
        if !round.isCancelled, !session.isCancelled, let date = session.date, date > context.date {
          let isScheduled = viewStore.reminders.scheduledDates[session.id] != nil
          Button {
            store.send(.toggleReminder(session.id))
          } label: {
            HStack(spacing: 6) {
              Label(isScheduled ? "Lembrete ativado" : "Avisar no início",
                    systemImage: isScheduled ? "bell.badge.fill" : "bell")
                .foregroundStyle(Color.primary)
              if viewStore.changingReminderID == session.id { ProgressView() }
            }
            .font(.subheadline)
          }
          .buttonStyle(.bordered)
          .disabled(viewStore.isLoadingReminders || viewStore.changingReminderID != nil)
          .accessibilityLabel(isScheduled ? "Desativar lembrete para \(session.title)" : "Avisar quando \(session.title) começar")
          .accessibilityValue(isScheduled ? "Ativado" : "Desativado")
        }
      }
    }
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
