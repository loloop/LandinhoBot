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
  private let injectedBackend: EvidenceNotifications?
  private let nativeBackend: LoggedNativeNotifications?
  private var initialReminders: StoreTask?
  @UIApplicationDelegateAdaptor var delegate: VroomAppDelegate

  init() {
    mode = ProcessInfo.processInfo.environment["LANDINHO_REMINDER_EVIDENCE"] ?? "off"
    round = Self.fixtureRound()
    baseline = Store(initialState: ReminderBaselineEventDetail.State(race: round)) {
      ReminderBaselineEventDetail()
    }
    if ["permission", "native-pending", "native-provisional"].contains(mode) {
      injectedBackend = nil
      let backend = LoggedNativeNotifications()
      nativeBackend = backend
      let center = SessionReminderCenter(backend: backend)
      store = Store(initialState: EventDetail.State(race: round)) { EventDetail() } withDependencies: {
        $0.sessionReminders = .init(
          current: { await center.current() },
          refresh: { try await center.refresh(rounds: $0) },
          toggle: { try await center.toggle(round: $0, session: $1) })
      }
    } else {
      nativeBackend = nil
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
    initialReminders = mode == "before" ? nil : store.send(.refreshReminders)
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
            // Wait for the real initial read instead of losing the user action
            // to the reducer's loading guard on a busy simulator.
            if let initialReminders { await initialReminders.finish() }
            if ["on", "cancel", "denied", "permission"].contains(mode) {
              // Delivers the same production action as the reminder button.
              // Injected modes test UI/state; permission mode invokes the real OS prompt.
              await store.send(.toggleReminder(round.events[0].id)).finish()
            } else if mode == "native-pending" {
              // Native scheduler primitive check only: permission is NOT granted here.
              // A pending request is not evidence that iOS displayed a notification.
              let backend = nativeBackend!
              do {
                let reminder = try SessionReminder.make(round: round, session: round.events[0], now: Date())
                try await backend.add(reminder)
                await store.send(.refreshReminders).finish()
                await recordNative(backend: backend, error: nil, phase: "scheduled")
              } catch {
                await recordNative(backend: backend, error: String(describing: error), phase: "scheduled")
              }
            } else if mode == "native-provisional" {
              await runNativeScenario()
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

  private func runNativeScenario() async {
    // PUBLIC Apple API used solely for evidence setup without an OS tap.
    // Shipping requestAuthorization remains an explicit alert/sound prompt.
    let backend = nativeBackend!
    var expectedStart = round.events[0].date!
    do {
      _ = try await backend.requestProvisionalAuthorization()
      let identifiers = round.events.map { SessionReminder.identifierPrefix + $0.id.uuidString }
      await backend.remove(identifiers: identifiers)
      UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: identifiers)
      await store.send(.refreshReminders).finish()
      await store.send(.toggleReminder(round.events[0].id)).finish()
      await recordNative(backend: backend, error: nil, phase: "scheduled", expectedStart: expectedStart)

      // Reconcile a changed source time through the production service.
      let center = SessionReminderCenter(backend: backend)
      var updated = round
      expectedStart = expectedStart.addingTimeInterval(10)
      updated.events[0] = .init(id: round.events[0].id, title: round.events[0].title,
                               date: expectedStart, isMainEvent: false)
      _ = try await center.refresh(rounds: [updated])
      await recordNative(backend: backend, error: nil, phase: "rescheduled", expectedStart: expectedStart)

      // Manual cancellation removes the second session without touching the first.
      _ = try await center.toggle(round: updated, session: updated.events[1])
      _ = try await center.toggle(round: updated, session: updated.events[1])
      await recordNative(backend: backend, error: nil, phase: "cancelled", expectedStart: expectedStart)

      // A supplied explicit source cancellation also removes that second reminder.
      _ = try await center.toggle(round: updated, session: updated.events[1])
      updated.events[1] = .init(id: round.events[1].id, title: round.events[1].title,
                               date: round.events[1].date, isMainEvent: true, isCancelled: true)
      _ = try await center.refresh(rounds: [updated])
      await recordNative(backend: backend, error: nil, phase: "source-cancelled", expectedStart: expectedStart)

      // Keep this evidence app in the foreground for the native delivery observation.
      try await Task.sleep(for: .seconds(max(0, expectedStart.timeIntervalSinceNow + 3)))
      await recordNative(backend: backend, error: nil, phase: "delivery", expectedStart: expectedStart)
    } catch {
      await recordNative(backend: backend, error: String(describing: error), phase: "failed", expectedStart: expectedStart)
    }
  }

  private func recordNative(backend: LoggedNativeNotifications, error: String?, phase: String,
                            expectedStart: Date? = nil) async {
    let pending = await backend.pending()
    let authorization = await backend.authorization()
    let requests = await backend.nativeRequests()
    let delivered = await backend.deliveredNotifications()
    let settings = await backend.settings()
    let expected = expectedStart ?? round.events[0].date!
    let identifier = SessionReminder.identifierPrefix + round.events[0].id.uuidString
    let sessionRequests = requests.filter { $0.identifier.hasPrefix(SessionReminder.identifierPrefix) }
    let sessionDelivery = delivered.first { $0.request.identifier == identifier }
    var failures: [String] = []
    if let error { failures.append(error) }
    if mode == "native-provisional" {
      if authorization != .allowed { failures.append("Native notifications were not authorized") }
      if phase == "delivery" {
        if sessionDelivery == nil { failures.append("No delivered notification for the opted-in session") }
        if sessionRequests.contains(where: { $0.identifier == identifier }) {
          failures.append("The delivered session still has a pending request")
        }
      } else if error == nil {
        if sessionRequests.count != 1 { failures.append("Expected exactly one pending session reminder") }
        if let request = sessionRequests.first, let trigger = request.trigger as? UNCalendarNotificationTrigger {
          if request.identifier != identifier { failures.append("Wrong session identifier") }
          if trigger.nextTriggerDate() != expected { failures.append("Native trigger does not match the expected start") }
          if trigger.repeats { failures.append("Session reminder must not repeat") }
          if trigger.dateComponents.timeZone != TimeZone(secondsFromGMT: 0) { failures.append("Trigger must use UTC") }
        } else { failures.append("Missing native calendar trigger") }
      }
    }
    Self.writeRecord([
      "mode": mode,
      "authorization": String(describing: authorization),
      "systemAuthorizationRawValue": settings.authorizationStatus.rawValue,
      "phase": phase,
      "failures": failures,
      "error": error ?? "",
      "scheduledSessionIDs": pending.reminders.map { $0.sessionID.uuidString },
      "expectedStartEpoch": expected.timeIntervalSince1970,
      "nativeRequests": sessionRequests.map {
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

// Transparent native adapter instrumentation; all notification operations still
// call the production adapter / documented Apple APIs. A watchdog reports the
// exact awaited API and app state without altering permissions or services.
private actor LoggedNativeNotifications: SessionNotificationBackend {
  private let backend = LocalSessionNotificationBackend()
  private var events: [[String: Any]] = []
  private var awaitedAPI: String?
  private var timedOutAPI: String?
  private var watchdog: Task<Void, Never>?

  func authorization() async -> SessionReminderAuthorization {
    await begin("notificationSettings")
    let result = await backend.authorization()
    await end("notificationSettings")
    return result
  }

  func requestAuthorization() async throws -> Bool {
    await begin("shippingRequestAuthorization")
    do {
      let result = try await backend.requestAuthorization()
      await end("shippingRequestAuthorization")
      return result
    } catch { await end("shippingRequestAuthorization", error: error); throw error }
  }

  func requestProvisionalAuthorization() async throws -> Bool {
    await begin("provisionalRequestAuthorization")
    do {
      let result = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .provisional])
      await end("provisionalRequestAuthorization")
      return result
    } catch { await end("provisionalRequestAuthorization", error: error); throw error }
  }

  func pending() async -> PendingSessionReminders {
    await begin("pendingNotificationRequests")
    let result = await backend.pending()
    await end("pendingNotificationRequests")
    return result
  }

  func add(_ reminder: SessionReminder) async throws {
    await begin("addNotificationRequest")
    do {
      try await backend.add(reminder)
      await end("addNotificationRequest")
    } catch { await end("addNotificationRequest", error: error); throw error }
  }

  func remove(identifiers: [String]) async { await backend.remove(identifiers: identifiers) }

  func nativeRequests() async -> [UNNotificationRequest] {
    await begin("rawPendingNotificationRequests")
    let result = await UNUserNotificationCenter.current().pendingNotificationRequests()
    await end("rawPendingNotificationRequests")
    return result
  }

  func deliveredNotifications() async -> [UNNotification] {
    await begin("deliveredNotifications")
    let result = await UNUserNotificationCenter.current().deliveredNotifications()
    await end("deliveredNotifications")
    return result
  }

  func settings() async -> UNNotificationSettings {
    await begin("rawNotificationSettings")
    let result = await UNUserNotificationCenter.current().notificationSettings()
    await end("rawNotificationSettings")
    return result
  }

  private func begin(_ api: String) async {
    watchdog?.cancel()
    awaitedAPI = api
    await record(api + ".begin")
    watchdog = Task {
      do {
        try await Task.sleep(for: .seconds(30))
        await timeout(api)
      } catch {}
    }
  }

  private func end(_ api: String, error: Error? = nil) async {
    watchdog?.cancel()
    awaitedAPI = nil
    await record(api + ".end", error: error.map(String.init(describing:)))
  }

  private func timeout(_ api: String) async {
    guard awaitedAPI == api else { return }
    timedOutAPI = api
    await record(api + ".timeout")
  }

  private func record(_ phase: String, error: String? = nil) async {
    let appState = await MainActor.run { UIApplication.shared.applicationState.rawValue }
    events.append(["phase": phase, "epoch": Date().timeIntervalSince1970,
                   "applicationState": appState, "error": error ?? ""])
    let record: [String: Any] = ["events": events, "awaitedAPI": awaitedAPI ?? "",
                                 "timedOutAPI": timedOutAPI ?? ""]
    let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    if let data = try? JSONSerialization.data(withJSONObject: record, options: [.prettyPrinted, .sortedKeys]) {
      try? data.write(to: directory.appendingPathComponent("session-reminder-native-phases.json"), options: .atomic)
    }
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
