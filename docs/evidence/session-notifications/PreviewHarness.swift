import ComposableArchitecture
import EventDetail
import Foundation
import LandinhoFoundation
import SessionReminders
import SwiftUI
import UserNotifications

// Evidence source only. Temporarily replaces VroomVroomApp.swift, then is restored.
// No private permission changes or native tap automation are used.
@main
struct VroomVroomApp: App {
  let store: StoreOf<EventDetail>
  let baseline: StoreOf<ReminderBaselineEventDetail>
  let mode: String
  let round: Race
  let injectedBackend: EvidenceNotifications?
  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  init() {
    mode = ProcessInfo.processInfo.environment["LANDINHO_REMINDER_EVIDENCE"] ?? "off"
    round = Self.fixtureRound()
    baseline = Store(initialState: ReminderBaselineEventDetail.State(race: round)) {
      ReminderBaselineEventDetail()
    }
    if ["permission", "native-pending", "native-provisional"].contains(mode) {
      injectedBackend = nil
      store = Store(initialState: EventDetail.State(race: round)) { EventDetail() }
    } else {
      let first = round.events[0]
      let existing = mode == "cancel" ? [try! SessionReminder.make(round: round, session: first, now: Date())] : []
      let backend = EvidenceNotifications(authorization: mode == "denied" ? .denied : .allowed, initial: existing)
      injectedBackend = backend
      let center = SessionReminderCenter(backend: backend)
      store = Store(initialState: EventDetail.State(race: round)) { EventDetail() } withDependencies: {
        $0.sessionReminders = .init(
          current: { await center.current() },
          refresh: { try await center.refresh(rounds: $0) },
          toggle: { try await center.toggle(round: $0, session: $1) })
      }
    }
  }

  var body: some Scene {
    WindowGroup {
      ScrollViewReader { proxy in
        NavigationStack {
          Group {
            if mode == "before" {
              ReminderBaselineEventDetailView(store: baseline)
            } else {
              EventDetailView(store: store)
            }
          }
          .task {
            try? await Task.sleep(for: .seconds(1))
            proxy.scrollTo(round.events[0].id, anchor: .top)
            if ["on", "cancel", "denied", "permission"].contains(mode) {
              // Delivers the same production action as the reminder button.
              // Injected modes test UI/state; permission mode invokes the real OS prompt.
              await store.send(.toggleReminder(round.events[0].id)).finish()
            } else if mode == "native-pending" {
              // Native scheduler primitive check only: permission is NOT granted here.
              // A pending request is not evidence that iOS displayed a notification.
              let backend = LocalSessionNotificationBackend()
              do {
                let reminder = try SessionReminder.make(round: round, session: round.events[0], now: Date())
                try await backend.add(reminder)
                await store.send(.refreshReminders).finish()
                await recordNative(backend: backend, error: nil, phase: "scheduled")
              } catch {
                await recordNative(backend: backend, error: String(describing: error), phase: "scheduled")
              }
            } else if mode == "native-provisional" {
              // PUBLIC Apple API used only for evidence setup without an OS tap.
              // Shipping requestAuthorization remains an explicit alert/sound prompt.
              let backend = LocalSessionNotificationBackend()
              do {
                _ = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .provisional])
                await backend.remove(identifiers: round.events.map { SessionReminder.identifierPrefix + $0.id.uuidString })
                await store.send(.refreshReminders).finish()
                await store.send(.toggleReminder(round.events[0].id)).finish()
                await recordNative(backend: backend, error: nil, phase: "scheduled")
                let delay = max(0, round.events[0].date!.timeIntervalSinceNow + 3)
                try await Task.sleep(for: .seconds(delay))
                await recordNative(backend: backend, error: nil, phase: "delivery")
              } catch {
                await recordNative(backend: backend, error: String(describing: error), phase: "scheduled")
              }
            }
            try? await Task.sleep(for: .seconds(1))
            proxy.scrollTo(round.events[0].id, anchor: .top)
            if let injectedBackend {
              let record = await injectedBackend.record()
              Self.writeRecord(record)
            }
          }
        }
      }
      .preferredColorScheme(.dark)
    }
  }

  private func recordNative(backend: LocalSessionNotificationBackend, error: String?, phase: String) async {
    let pending = await backend.pending()
    let authorization = await backend.authorization()
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let delivered = await UNUserNotificationCenter.current().deliveredNotifications()
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    Self.writeRecord([
      "mode": mode,
      "authorization": String(describing: authorization),
      "systemAuthorizationRawValue": settings.authorizationStatus.rawValue,
      "phase": phase,
      "error": error ?? "",
      "scheduledSessionIDs": pending.reminders.map { $0.sessionID.uuidString },
      "expectedStartEpoch": round.events[0].date!.timeIntervalSince1970,
      "nativeRequests": requests.filter { $0.identifier.hasPrefix(SessionReminder.identifierPrefix) }.map {
        let trigger = $0.trigger as? UNCalendarNotificationTrigger
        return ["identifier": $0.identifier, "title": $0.content.title, "body": $0.content.body,
                "repeats": trigger?.repeats ?? true,
                "nextTriggerEpoch": trigger?.nextTriggerDate()?.timeIntervalSince1970 ?? -1,
                "timeZone": trigger?.dateComponents.timeZone?.identifier ?? ""] as [String: Any]
      },
      "deliveredNotifications": delivered.filter { $0.request.identifier.hasPrefix(SessionReminder.identifierPrefix) }.map {
        ["identifier": $0.request.identifier, "title": $0.request.content.title,
         "body": $0.request.content.body, "deliveredEpoch": $0.date.timeIntervalSince1970] as [String: Any]
      }
    ], name: "session-reminder-native-\(phase).json")
  }

  private static func writeRecord(_ record: [String: Any], name: String = "session-reminder-evidence.json") {
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let url = directory.appendingPathComponent(name)
    if let data = try? JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]) {
      try? data.write(to: url, options: .atomic)
    }
  }

  private static func fixtureRound() -> Race {
    let formatter = ISO8601DateFormatter()
    let start = ProcessInfo.processInfo.environment["LANDINHO_REMINDER_START"].flatMap(formatter.date(from:))
      ?? Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970) + 3600)
    return Race(
      id: UUID(uuidString: "11111111-1111-1111-1111-111111111111")!,
      title: "Grande Prêmio de São Paulo", shortTitle: "São Paulo",
      events: [
        .init(id: UUID(uuidString: "22222222-2222-2222-2222-222222222222")!, title: "Classificação", date: start, isMainEvent: false),
        .init(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!, title: "Corrida", date: start.addingTimeInterval(86400), isMainEvent: true),
        .init(id: UUID(uuidString: "44444444-4444-4444-4444-444444444444")!, title: "Treino livre", date: start.addingTimeInterval(7200), isMainEvent: false, isCancelled: true),
        .init(id: UUID(uuidString: "55555555-5555-5555-5555-555555555555")!, title: "Sprint", date: nil, isMainEvent: false, scheduledDay: "2026-10-04")
      ],
      category: .init(id: "f1", title: "Formula 1", tag: "f1"))
  }
}

// This backend is deliberately injected: it validates production service/reducer/UI
// transitions without presenting its state as a real iOS permission grant or delivery.
private actor EvidenceNotifications: SessionNotificationBackend {
  init(authorization: SessionReminderAuthorization, initial: [SessionReminder]) {
    status = authorization
    reminders = Dictionary(uniqueKeysWithValues: initial.map { ($0.identifier, $0) })
  }

  let status: SessionReminderAuthorization
  var reminders: [String: SessionReminder]
  var additions = 0
  var removals = 0
  var permissionRequests = 0

  func authorization() -> SessionReminderAuthorization { status }
  func requestAuthorization() -> Bool { permissionRequests += 1; return status == .allowed }
  func pending() -> PendingSessionReminders {
    .init(reminders: Array(reminders.values), totalRequestCount: reminders.count)
  }
  func add(_ reminder: SessionReminder) { reminders[reminder.identifier] = reminder; additions += 1 }
  func remove(identifiers: [String]) {
    for identifier in identifiers { reminders.removeValue(forKey: identifier); removals += 1 }
  }
  func record() -> [String: Any] {
    ["backend": "injected evidence backend", "authorization": String(describing: status),
     "permissionRequests": permissionRequests, "additions": additions, "removals": removals,
     "scheduledSessionIDs": reminders.values.map { $0.sessionID.uuidString }]
  }
}
