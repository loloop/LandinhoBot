import XCTest
import ComposableArchitecture
@_spi(Internal) import APIClient
import LandinhoFoundation
import SessionReminders
@testable import EventDetail

@MainActor
final class EventDetailTests: XCTestCase {
  func testFetchByIDUsesPublicEndpointAndRepeatedAppearanceDoesNotRestart() async {
    let race = makeRace()
    let recorder = RequestRecorder()
    let reminders = DetailReminderRecorder()
    let snapshot = SessionReminderSnapshot(authorization: .allowed, scheduledDates: [:])
    let clock = TestClock()
    let store = TestStore(initialState: EventDetail.State(raceID: race.id)) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { endpoint in
      await recorder.record(endpoint)
      try await clock.sleep(for: .seconds(1))
      return race
    }
    store.dependencies.sessionReminders.refresh = { rounds in
      await reminders.record(rounds)
      return snapshot
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.send(.onAppear)
    await clock.advance(by: .seconds(1))
    await store.receive(.response(.success(race))) {
      $0.isLoading = false
      $0.race = race
    }
    await store.receive(.refreshReminders) { $0.isLoadingReminders = true }
    await store.receive(.reminderResponse(.success(snapshot))) {
      $0.isLoadingReminders = false
      $0.reminders = snapshot
    }
    await store.send(.onAppear)
    await store.receive(.refreshReminders) { $0.isLoadingReminders = true }
    await store.receive(.reminderResponse(.success(snapshot))) { $0.isLoadingReminders = false }
    await store.finish()
    let endpoints = await recorder.endpoints
    XCTAssertEqual(endpoints, ["rounds/" + race.id.uuidString.lowercased()])
    let reconciled = await reminders.rounds
    XCTAssertEqual(reconciled, [[race], [race]])
  }

  func testNotFoundShowsRecoverableFailureAndRetryLoadsRound() async {
    let race = makeRace()
    let recorder = RequestRecorder()
    let reminders = DetailReminderRecorder()
    let snapshot = SessionReminderSnapshot(authorization: .notDetermined, scheduledDates: [:])
    let failure = NSError(domain: "LandinhoAPI", code: 404)
    let store = TestStore(initialState: EventDetail.State(raceID: race.id)) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { endpoint in
      let attempt = await recorder.record(endpoint)
      if attempt == 1 { throw failure }
      return race
    }
    store.dependencies.sessionReminders.refresh = { rounds in
      await reminders.record(rounds)
      return snapshot
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.receive(.response(.failure(failure))) {
      $0.isLoading = false
      $0.loadFailure = .notFound
    }
    let failedReconciliation = await reminders.rounds
    XCTAssertTrue(failedReconciliation.isEmpty)
    await store.send(.onAppear)
    await store.send(.retry) {
      $0.isLoading = true
      $0.loadFailure = nil
    }
    await store.receive(.response(.success(race))) {
      $0.isLoading = false
      $0.race = race
    }
    await store.receive(.refreshReminders) { $0.isLoadingReminders = true }
    await store.receive(.reminderResponse(.success(snapshot))) { $0.isLoadingReminders = false }
    await store.finish()
    let reconciled = await reminders.rounds
    XCTAssertEqual(reconciled, [[race]])
  }

  func testLeavingCancelsRequestWithoutPresentingAnError() async {
    let race = makeRace()
    let store = TestStore(initialState: EventDetail.State(raceID: UUID())) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { _ in
      try await Task.sleep(nanoseconds: 30_000_000_000)
      return race
    }
    store.dependencies.sessionReminders.refresh = { _ in
      XCTFail("A cancelled fetch must not reconcile reminders")
      return .init(authorization: .notDetermined, scheduledDates: [:])
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.send(.onDisappear) { $0.isLoading = false }
    await store.finish()
    XCTAssertNil(store.state.loadFailure)
  }

  func testWrongRoundIDCannotShowAnUnrelatedRound() async {
    let race = makeRace()
    let store = TestStore(initialState: EventDetail.State(raceID: UUID())) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { _ in race }
    store.dependencies.sessionReminders.refresh = { _ in
      XCTFail("An unrelated round must not reconcile reminders")
      return .init(authorization: .notDetermined, scheduledDates: [:])
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.receive(.response(.success(race))) {
      $0.isLoading = false
      $0.loadFailure = .unavailable
    }
    XCTAssertNil(store.state.race)
    await store.finish()
  }

  func testPreloadedRoundNeverFetchesAndReconcilesPendingReminders() async {
    let race = makeRace()
    let reminders = DetailReminderRecorder()
    let snapshot = SessionReminderSnapshot(authorization: .denied, scheduledDates: [:])
    let store = TestStore(initialState: EventDetail.State(race: race)) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { _ in
      XCTFail("A preloaded round should not request the API")
      return race
    }
    store.dependencies.sessionReminders.refresh = { rounds in
      await reminders.record(rounds)
      return snapshot
    }
    await store.send(.onAppear)
    await store.receive(.refreshReminders) { $0.isLoadingReminders = true }
    await store.receive(.reminderResponse(.success(snapshot))) {
      $0.isLoadingReminders = false
      $0.reminders = snapshot
      $0.isNotificationSettingsNeeded = true
    }
    await store.finish()
    let reconciled = await reminders.rounds
    XCTAssertEqual(reconciled, [[race]])
  }

  func testReminderToggleWaitsForRefreshAndSchedulingBeforeShowingEnabledState() async {
    var round = makeRace()
    let session = RaceEvent(id: UUID(), title: "Classificação", date: Date().addingTimeInterval(3600), isMainEvent: false)
    round.events = [session]
    let race = round
    let loaded = SessionReminderSnapshot(authorization: .allowed, scheduledDates: [:])
    let enabled = SessionReminderSnapshot(authorization: .allowed, scheduledDates: [session.id: session.date!])
    let clock = TestClock()
    let store = TestStore(initialState: EventDetail.State(race: race)) { EventDetail() }
    store.dependencies.sessionReminders = .init(
      current: { loaded },
      refresh: { _ in
        try await clock.sleep(for: .seconds(1))
        return loaded
      },
      toggle: { round, selected in
        XCTAssertEqual(round.id, race.id)
        XCTAssertEqual(selected, session)
        try await clock.sleep(for: .seconds(1))
        return enabled
      })
    await store.send(.onAppear)
    await store.receive(.refreshReminders) { $0.isLoadingReminders = true }
    await store.send(.toggleReminder(session.id))
    await clock.advance(by: .seconds(1))
    await store.receive(.reminderResponse(.success(loaded))) {
      $0.isLoadingReminders = false
      $0.reminders = loaded
    }
    await store.send(.toggleReminder(session.id)) { $0.changingReminderID = session.id }
    await store.send(.toggleReminder(session.id))
    XCTAssertNil(store.state.reminders.scheduledDates[session.id])
    await clock.advance(by: .seconds(1))
    await store.receive(.reminderResponse(.success(enabled))) {
      $0.reminders = enabled
      $0.changingReminderID = nil
    }
    await store.finish()
  }

  func testReminderDenialReloadsActualPendingStateAndExposesSettings() async {
    var round = makeRace()
    let session = RaceEvent(id: UUID(), title: "Corrida", date: Date().addingTimeInterval(3600), isMainEvent: true)
    round.events = [session]
    let race = round
    let denied = SessionReminderSnapshot(authorization: .denied, scheduledDates: [:])
    let store = TestStore(initialState: EventDetail.State(race: race)) { EventDetail() }
    store.dependencies.sessionReminders = .init(
      current: { denied }, refresh: { _ in denied },
      toggle: { _, _ in throw SessionReminderError.permissionDenied })
    await store.send(.toggleReminder(session.id)) { $0.changingReminderID = session.id }
    await store.receive(.reminderResponse(.failure(SessionReminderError.permissionDenied))) {
      $0.changingReminderID = nil
      $0.isLoadingReminders = true
      $0.isNotificationSettingsNeeded = true
      $0.reminderError = "Permita notificações nos Ajustes para receber este lembrete."
    }
    await store.receive(.reminderState(denied)) {
      $0.isLoadingReminders = false
      $0.reminders = denied
    }
    XCTAssertTrue(store.state.reminders.scheduledDates.isEmpty)
    await store.finish()
  }

  private func makeRace() -> Race {
    Race(id: UUID(), title: "São Paulo Grand Prix", shortTitle: "São Paulo", events: [],
      category: RaceCategory(id: "f1", title: "Formula 1", tag: "f1"))
  }
}

private actor RequestRecorder {
  var endpoints: [String] = []
  @discardableResult func record(_ endpoint: String) -> Int {
    endpoints.append(endpoint)
    return endpoints.count
  }
}

private actor DetailReminderRecorder {
  var rounds: [[Race]] = []
  func record(_ value: [Race]) { rounds.append(value) }
}

private struct RoundRequester: APIClientServiceProtocol {
  static let liveValue = Self { _ in throw URLError(.unsupportedURL) }
  let load: (String) async throws -> Race
  init(_ load: @escaping (String) async throws -> Race) { self.load = load }
  func request<T: Decodable>(_: T.Type, endpoint: String, method: String, data: Data?,
    queryItems: [URLQueryItem], headers: [String: String]) async throws -> T {
    XCTAssertEqual(method, "GET")
    XCTAssertNil(data)
    XCTAssertTrue(queryItems.isEmpty)
    XCTAssertTrue(headers.isEmpty)
    guard let response = try await load(endpoint) as? T else { throw URLError(.cannotParseResponse) }
    return response
  }
  func setPersistentHeaders(_ headers: [String: String]) {}
}
