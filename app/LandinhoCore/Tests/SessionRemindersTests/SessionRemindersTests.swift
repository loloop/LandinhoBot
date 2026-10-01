import Foundation
import LandinhoFoundation
@testable import SessionReminders
import XCTest

final class SessionRemindersTests: XCTestCase {
  let now = Date(timeIntervalSince1970: 1_800_000_000)
  let roundID = UUID(uuidString: "11111111-1111-1111-1111-111111111111")!
  let sessionID = UUID(uuidString: "22222222-2222-2222-2222-222222222222")!

  func testLoadingDoesNotRequestPermissionOrScheduleAnything() async throws {
    let backend = FakeNotifications(authorization: .notDetermined)
    let center = makeCenter(backend)
    let state = try await center.refresh(rounds: [round()])
    XCTAssertEqual(state.authorization, .notDetermined)
    XCTAssertTrue(state.scheduledDates.isEmpty)
    let history = await backend.history()
    XCTAssertEqual(history.permissionRequests, 0)
    XCTAssertEqual(history.additions, 0)
  }

  func testOptInSchedulesOnlySelectedSessionAtItsAbsoluteStart() async throws {
    let backend = FakeNotifications(authorization: .notDetermined)
    let center = makeCenter(backend)
    let round = round()
    let state = try await center.toggle(round: round, session: round.events[0])
    let history = await backend.history()
    XCTAssertEqual(history.permissionRequests, 1)
    XCTAssertEqual(history.reminders.count, 1)
    let reminder = try XCTUnwrap(history.reminders.first)
    XCTAssertEqual(reminder.roundID, roundID)
    XCTAssertEqual(reminder.sessionID, sessionID)
    XCTAssertEqual(reminder.date, round.events[0].date)
    XCTAssertEqual(reminder.title, "Classificação vai começar")
    XCTAssertTrue(reminder.body.contains("Formula 1 · São Paulo"))
    XCTAssertEqual(state.scheduledDates, [sessionID: reminder.date])
    XCTAssertEqual(reminder.dateComponents.timeZone, TimeZone(secondsFromGMT: 0))
    XCTAssertEqual(reminder.dateComponents.calendar?.date(from: reminder.dateComponents), reminder.date)
  }

  func testDateComponentsPreserveInstantAcrossDSTAndYearBoundary() throws {
    let formatter = ISO8601DateFormatter()
    for instant in ["2026-11-01T05:30:00Z", "2026-11-01T06:30:00Z", "2027-01-01T00:00:00Z"] {
      let date = try XCTUnwrap(formatter.date(from: instant))
      let reminder = SessionReminder(roundID: roundID, sessionID: sessionID, date: date, title: "", body: "")
      XCTAssertEqual(Calendar(identifier: .gregorian).date(from: reminder.dateComponents), date)
      XCTAssertEqual(reminder.dateComponents.timeZone?.secondsFromGMT(for: date), 0)
    }
  }

  func testToggleCancelsOnlySelectedSessionEvenAfterPermissionWasDenied() async throws {
    let backend = FakeNotifications(authorization: .allowed)
    let center = makeCenter(backend)
    let round = round()
    _ = try await center.toggle(round: round, session: round.events[0])
    _ = try await center.toggle(round: round, session: round.events[1])
    await backend.setAuthorization(.denied)
    let state = try await center.toggle(round: round, session: round.events[0])
    XCTAssertNil(state.scheduledDates[sessionID])
    XCTAssertNotNil(state.scheduledDates[round.events[1].id])
    let history = await backend.history()
    XCTAssertEqual(history.permissionRequests, 0)
    XCTAssertEqual(history.removals.count, 1)
  }

  func testDenialDoesNotClaimScheduledAndDoesNotPromptAgain() async throws {
    let backend = FakeNotifications(authorization: .notDetermined, grantsPermission: false)
    let center = makeCenter(backend)
    let round = round()
    for _ in 0..<2 {
      do {
        _ = try await center.toggle(round: round, session: round.events[0])
        XCTFail("Denied permission must fail")
      } catch {
        XCTAssertEqual(error as? SessionReminderError, .permissionDenied)
      }
    }
    let history = await backend.history()
    XCTAssertEqual(history.permissionRequests, 1)
    XCTAssertTrue(history.reminders.isEmpty)
    // Returning from Settings can grant permission without another prompt.
    await backend.setAuthorization(.allowed)
    _ = try await center.toggle(round: round, session: round.events[0])
    let afterSettings = await backend.history()
    XCTAssertEqual(afterSettings.permissionRequests, 1)
    XCTAssertEqual(afterSettings.reminders.count, 1)
  }

  func testCancelledPendingAndPastSessionsNeverAskForPermission() async throws {
    let backend = FakeNotifications(authorization: .notDetermined)
    let center = makeCenter(backend)
    for (session, expected) in [
      (event(date: now.addingTimeInterval(60), cancelled: true), SessionReminderError.cancelled),
      (event(date: nil), .pendingTime),
      (event(date: now), .alreadyStarted),
      (event(date: now.addingTimeInterval(-1)), .alreadyStarted)
    ] {
      do {
        _ = try await center.toggle(round: round(), session: session)
        XCTFail("Ineligible session must fail")
      } catch { XCTAssertEqual(error as? SessionReminderError, expected) }
    }
    do {
      _ = try await center.toggle(round: round(cancelled: true), session: round().events[0])
      XCTFail("Cancelled round must fail")
    } catch { XCTAssertEqual(error as? SessionReminderError, .cancelled) }
    let history = await backend.history()
    XCTAssertEqual(history.permissionRequests, 0)
    XCTAssertEqual(history.additions, 0)
  }

  func testSessionThatStartsDuringPermissionPromptIsNotScheduled() async throws {
    let clock = TestClock(now)
    let backend = FakeNotifications(authorization: .notDetermined, permissionHook: { clock.advance(7200) })
    let center = SessionReminderCenter(backend: backend, now: { clock.value })
    do {
      _ = try await center.toggle(round: round(), session: round().events[0])
      XCTFail("Session has already started")
    } catch { XCTAssertEqual(error as? SessionReminderError, .alreadyStarted) }
    let history = await backend.history()
    XCTAssertTrue(history.reminders.isEmpty)
  }

  func testRefreshUpdatesExistingReminderWithoutOptingInOtherSessions() async throws {
    let backend = FakeNotifications(authorization: .allowed)
    let center = makeCenter(backend)
    _ = try await center.toggle(round: round(), session: round().events[0])
    let updated = round(first: event(date: now.addingTimeInterval(10800)))
    let state = try await center.refresh(rounds: [updated])
    XCTAssertEqual(state.scheduledDates, [sessionID: now.addingTimeInterval(10800)])
    let history = await backend.history()
    XCTAssertEqual(history.reminders.count, 1)
    XCTAssertEqual(history.permissionRequests, 0)
    XCTAssertEqual(history.additions, 2)
  }

  func testRefreshCancelsKnownCancellationPendingTimeAndPastButNotAbsentData() async throws {
    for updated in [
      round(first: event(date: now.addingTimeInterval(3600), cancelled: true)),
      round(first: event(date: nil)),
      round(first: event(date: now)),
      round(cancelled: true)
    ] {
      let backend = FakeNotifications(authorization: .allowed)
      let center = makeCenter(backend)
      _ = try await center.toggle(round: round(), session: round().events[0])
      let state = try await center.refresh(rounds: [updated])
      XCTAssertTrue(state.scheduledDates.isEmpty)
    }
    let backend = FakeNotifications(authorization: .allowed)
    let center = makeCenter(backend)
    _ = try await center.toggle(round: round(), session: round().events[0])
    let emptyPage = try await center.refresh(rounds: [])
    XCTAssertNotNil(emptyPage.scheduledDates[sessionID])
    var missingSession = round()
    missingSession.events = []
    let missing = try await center.refresh(rounds: [missingSession])
    XCTAssertNotNil(missing.scheduledDates[sessionID])
  }

  func testFailedRescheduleRemovesKnownObsoleteTimeAndCanRetry() async throws {
    let backend = FakeNotifications(authorization: .allowed)
    let center = makeCenter(backend)
    var original = round()
    original.events[1] = .init(id: UUID(uuidString: "33333333-3333-3333-3333-333333333333")!,
                             title: "Corrida", date: now.addingTimeInterval(86400), isMainEvent: true)
    _ = try await center.toggle(round: original, session: original.events[0])
    _ = try await center.toggle(round: original, session: original.events[1])
    await backend.failAdds(true)
    var updated = original
    updated.events[0] = event(date: now.addingTimeInterval(10800))
    updated.events[1] = .init(id: original.events[1].id, title: "Corrida", date: original.events[1].date,
                            isMainEvent: true, isCancelled: true)
    do {
      _ = try await center.refresh(rounds: [updated])
      XCTFail("Scheduling error should be visible")
    } catch { XCTAssertEqual(error as? SessionReminderError, .schedulingFailed) }
    let state = await center.current()
    // An earlier failed update must not stop cancellation of another session.
    XCTAssertTrue(state.scheduledDates.isEmpty)
    await backend.failAdds(false)
    let retried = try await center.toggle(round: updated, session: updated.events[0])
    XCTAssertEqual(retried.scheduledDates[sessionID], now.addingTimeInterval(10800))
  }

  func testCapacityDoesNotSilentlyEvictExistingReminders() async throws {
    let backend = FakeNotifications(authorization: .allowed, otherRequestCount: 60)
    let center = makeCenter(backend)
    do {
      _ = try await center.toggle(round: round(), session: round().events[0])
      XCTFail("Capacity must fail explicitly")
    } catch { XCTAssertEqual(error as? SessionReminderError, .limitReached) }
    let history = await backend.history()
    XCTAssertEqual(history.additions, 0)
  }

  func testConcurrentTogglesDoNotCreateDuplicateOrStaleReminders() async throws {
    let backend = FakeNotifications(authorization: .allowed)
    let center = makeCenter(backend)
    let round = round()
    async let first = center.toggle(round: round, session: round.events[0])
    async let second = center.toggle(round: round, session: round.events[0])
    _ = try await (first, second)
    let history = await backend.history()
    XCTAssertEqual(history.additions, 1)
    XCTAssertEqual(history.removals.count, 1)
    XCTAssertTrue(history.reminders.isEmpty)
  }

  private func makeCenter(_ backend: FakeNotifications) -> SessionReminderCenter {
    let instant = now
    return SessionReminderCenter(backend: backend, now: { instant })
  }

  private func event(date: Date?, cancelled: Bool = false) -> RaceEvent {
    .init(id: sessionID, title: "Classificação", date: date, isMainEvent: false, isCancelled: cancelled)
  }

  private func round(first: RaceEvent? = nil, cancelled: Bool = false) -> Race {
    .init(id: roundID, title: "Grande Prêmio de São Paulo", shortTitle: "São Paulo",
          events: [first ?? event(date: now.addingTimeInterval(3600)),
                   .init(id: UUID(), title: "Corrida", date: now.addingTimeInterval(86400), isMainEvent: true)],
          category: .init(id: "f1", title: "Formula 1", tag: "f1"), isCancelled: cancelled)
  }
}

private actor FakeNotifications: SessionNotificationBackend {
  init(authorization: SessionReminderAuthorization, grantsPermission: Bool = true,
       otherRequestCount: Int = 0, permissionHook: @escaping @Sendable () -> Void = {}) {
    status = authorization
    self.grantsPermission = grantsPermission
    self.otherRequestCount = otherRequestCount
    self.permissionHook = permissionHook
  }

  var status: SessionReminderAuthorization
  let grantsPermission: Bool
  let otherRequestCount: Int
  let permissionHook: @Sendable () -> Void
  var reminders: [String: SessionReminder] = [:]
  var permissionRequests = 0
  var additions = 0
  var removals: [String] = []
  var shouldFailAdds = false

  func authorization() -> SessionReminderAuthorization { status }
  func setAuthorization(_ value: SessionReminderAuthorization) { status = value }
  func failAdds(_ value: Bool) { shouldFailAdds = value }

  func requestAuthorization() -> Bool {
    permissionRequests += 1
    permissionHook()
    status = grantsPermission ? .allowed : .denied
    return grantsPermission
  }

  func pending() -> PendingSessionReminders {
    .init(reminders: reminders.values.sorted { $0.sessionID.uuidString < $1.sessionID.uuidString },
          totalRequestCount: reminders.count + otherRequestCount)
  }

  func add(_ reminder: SessionReminder) throws {
    if shouldFailAdds { throw SessionReminderError.schedulingFailed }
    reminders[reminder.identifier] = reminder
    additions += 1
  }

  func remove(identifiers: [String]) {
    for id in identifiers {
      reminders.removeValue(forKey: id)
      removals.append(id)
    }
  }

  func history() -> (permissionRequests: Int, additions: Int, removals: [String], reminders: [SessionReminder]) {
    (permissionRequests, additions, removals, Array(reminders.values))
  }
}

private final class TestClock: @unchecked Sendable {
  init(_ value: Date) { instant = value }
  private var instant: Date
  private let lock = NSLock()
  var value: Date {
    lock.lock()
    defer { lock.unlock() }
    return instant
  }
  func advance(_ interval: TimeInterval) {
    lock.lock()
    defer { lock.unlock() }
    instant = instant.addingTimeInterval(interval)
  }
}
