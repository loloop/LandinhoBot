import CategoryFavorites
import ComposableArchitecture
import EventDetail
import Foundation
import LandinhoFoundation
import SessionReminders
@testable import ScheduleList
import XCTest

@MainActor
final class ScheduleListTests: XCTestCase {
  let date = Date(timeIntervalSince1970: 1_800_000_000)

  func testInitialLoadOnlyOnceAndPaginationDeduplicatesEveryPage() async {
    let races = (0..<4).map { race($0) }
    let clock = TestClock()
    let store = TestStore(initialState: ScheduleList.State(categoryTag: nil, pageSize: 2)) { ScheduleList() } withDependencies: {
      $0.date.now = date
      $0.scheduleClient = .init { category, favorites, page, per in
        try await clock.sleep(for: .seconds(1))
        XCTAssertNil(category)
        XCTAssertEqual(per, 2)
        let items = page == 1 ? [races[0], races[1]] : page == 2 ? [races[1], races[2]] : [races[3]]
        return .init(items: items, metadata: .init(page: page, per: per, total: 5))
      }
    }
    store.exhaustivity = .off
    await store.send(.onAppear)
    await store.send(.onAppear)
    XCTAssertEqual(store.state.requestGeneration, 1)
    await clock.advance(by: .seconds(1))
    await store.receive(.pageResponse(generation: 1, page: 1, .success(.init(items: Array(races.prefix(2)), metadata: .init(page: 1, per: 2, total: 5)))))
    await store.send(.loadMore)
    await store.send(.loadMore)
    XCTAssertEqual(store.state.requestGeneration, 2)
    await clock.advance(by: .seconds(1))
    await store.receive(.pageResponse(generation: 2, page: 2, .success(.init(items: [races[1], races[2]], metadata: .init(page: 2, per: 2, total: 5)))))
    XCTAssertEqual(store.state.items.map(\.id), Array(races.prefix(3)).map(\.id))
    await store.send(.loadMore)
    await clock.advance(by: .seconds(1))
    await store.receive(.pageResponse(generation: 3, page: 3, .success(.init(items: [races[3]], metadata: .init(page: 3, per: 2, total: 5)))))
    XCTAssertEqual(store.state.items, races)
    XCTAssertFalse(store.state.canLoadMore)
    await store.send(.loadMore)
    await store.send(.onAppear)
    XCTAssertEqual(store.state.requestGeneration, 3)
  }

  func testFailureKeepsLoadedRoundsAndRetryUsesFailedPage() async {
    var state = ScheduleList.State(categoryTag: "f1", pageSize: 2)
    state.items = [race(0), race(1)]
    state.hasLoaded = true; state.currentPage = 1; state.total = 4
    let error = URLError(.notConnectedToInternet)
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.scheduleClient = .init { category, _, _, _ in
        XCTAssertEqual(category, "f1")
        throw error
      }
    }
    store.exhaustivity = .off
    await store.send(.loadMore)
    await store.receive(.pageResponse(generation: 1, page: 2, .failure(error)))
    XCTAssertEqual(store.state.items, state.items)
    XCTAssertEqual(store.state.currentPage, 1)
    XCTAssertEqual(store.state.failedPage, 2)
    XCTAssertNotNil(store.state.errorMessage)
    await store.send(.retry)
    XCTAssertEqual(store.state.inFlightPage, 2)
    await store.receive(.pageResponse(generation: 2, page: 2, .failure(error)))
    await store.send(.refresh)
    await store.receive(.pageResponse(generation: 3, page: 1, .failure(error)))
    XCTAssertEqual(store.state.items, state.items)
    await store.send(.retry)
    XCTAssertEqual(store.state.inFlightPage, 1)
    await store.receive(.pageResponse(generation: 4, page: 1, .failure(error)))
  }

  func testFavoriteChangeRestartsPaginationAndLateResponseCannotReplaceNewOrder() async {
    let clock = TestClock()
    let previous = race(0)
    let favorite = race(1, tag: "stock")
    var state = ScheduleList.State(categoryTag: nil)
    state.items = [previous]; state.hasLoaded = true; state.currentPage = 2; state.total = 20
    state.requestGeneration = 4; state.inFlightPage = 3
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.date.now = date
      $0.scheduleClient = .init { category, favorites, page, per in
        try await clock.sleep(for: .seconds(1))
        XCTAssertNil(category)
        XCTAssertEqual(favorites, ["stock"])
        XCTAssertEqual(page, 1)
        return .init(items: [favorite], metadata: .init(page: page, per: per, total: 1))
      }
    }
    store.exhaustivity = .off
    await store.send(.favoritesChanged(["stock"]))
    XCTAssertTrue(store.state.items.isEmpty)
    XCTAssertEqual(store.state.requestGeneration, 5)
    await store.send(.pageResponse(generation: 4, page: 3, .success(.init(items: [previous], metadata: .init(page: 3, per: 5, total: 20)))))
    XCTAssertTrue(store.state.items.isEmpty)
    XCTAssertEqual(store.state.inFlightPage, 1)
    await clock.advance(by: .seconds(1))
    await store.receive(.pageResponse(generation: 5, page: 1, .success(.init(items: [favorite], metadata: .init(page: 1, per: 5, total: 1)))))
    XCTAssertEqual(store.state.items, [favorite])
    XCTAssertEqual(store.state.favoriteTags, ["stock"])
    XCTAssertFalse(store.state.canLoadMore)
  }

  func testEmptyRefreshReplacesOldPages() async {
    var state = ScheduleList.State(categoryTag: nil)
    state.items = [race(0)]; state.hasLoaded = true; state.currentPage = 2; state.total = 10
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.date.now = date
      $0.scheduleClient = .init { _, _, page, per in .init(items: [], metadata: .init(page: page, per: per, total: 0)) }
    }
    store.exhaustivity = .off
    await store.send(.refresh)
    XCTAssertTrue(store.state.isRefreshing)
    await store.receive(.pageResponse(generation: 1, page: 1, .success(.init(items: [], metadata: .init(page: 1, per: 5, total: 0)))))
    XCTAssertTrue(store.state.items.isEmpty)
    XCTAssertFalse(store.state.canLoadMore)
    XCTAssertNil(store.state.errorMessage)
  }

  func testLeavingScreenCancelsLoadingAndLateResponseIsIgnoredOnReturn() async {
    var state = ScheduleList.State(categoryTag: nil)
    state.inFlightPage = 1; state.requestGeneration = 1
    let round = race(0)
    let page = Page(items: [round], metadata: .init(page: 1, per: 5, total: 1))
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.date.now = date
      $0.scheduleClient = .init { _, _, _, _ in page }
    }
    store.exhaustivity = .off
    await store.send(.onDisappear)
    XCTAssertFalse(store.state.isLoading)
    XCTAssertEqual(store.state.requestGeneration, 2)
    await store.send(.pageResponse(generation: 1, page: 1, .success(page)))
    XCTAssertTrue(store.state.items.isEmpty)
    await store.send(.onAppear)
    await store.receive(.pageResponse(generation: 3, page: 1, .success(page)))
    XCTAssertEqual(store.state.items, [round])
  }

  func testFavoritesPersistAcrossStoreInstances() {
    let suite = "home-favorites-test-\(UUID())"
    let defaults = UserDefaults(suiteName: suite)!
    defer { defaults.removePersistentDomain(forName: suite) }
    let first = CategoryFavorites(defaults: defaults)
    first.write(["stock", "f1"])
    XCTAssertEqual(CategoryFavorites(defaults: UserDefaults(suiteName: suite)!).read(), ["f1", "stock"])
    first.write(["stock"])
    XCTAssertEqual(CategoryFavorites(defaults: defaults).read(), ["stock"])
  }

  func testValidatedRefreshReconcilesRawRoundsIncludingCancellations() async {
    let live = race(1)
    let cancelled = Race(id: race(2).id, title: "Cancelled round", shortTitle: "Cancelled",
      events: [], category: live.category, isCancelled: true)
    let response = Page(items: [live, cancelled, live], metadata: .init(page: 1, per: 5, total: 3))
    var state = ScheduleList.State(categoryTag: nil)
    state.items = [race(0)]
    state.hasLoaded = true
    state.currentPage = 2
    state.total = 10
    state.requestGeneration = 9
    state.inFlightPage = 1
    state.isRefreshing = true
    let recorder = ScheduleReminderRecorder()
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.date.now = date
      $0.sessionReminders.refresh = { rounds in
        await recorder.record(rounds)
        return .init(authorization: .allowed, scheduledDates: [:])
      }
    }
    await store.send(.pageResponse(generation: 9, page: 1, .success(response))) {
      $0.inFlightPage = nil
      $0.isRefreshing = false
      $0.items = [live]
      $0.currentPage = 1
      $0.total = 3
      $0.lastUpdatedDate = self.date
    }
    await store.finish()
    let reconciled = await recorder.rounds
    XCTAssertEqual(reconciled, [response.items])
    XCTAssertEqual(store.state.items, [live])
  }

  func testStaleOrWrongPageCannotReconcileReminders() async {
    let response = Page(items: [race(0)], metadata: .init(page: 1, per: 5, total: 1))
    var state = ScheduleList.State(categoryTag: nil)
    state.requestGeneration = 9
    state.inFlightPage = 1
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.sessionReminders.refresh = { _ in
        XCTFail("An ignored response must not reconcile reminders")
        return .init(authorization: .allowed, scheduledDates: [:])
      }
    }
    await store.send(.pageResponse(generation: 8, page: 1, .success(response)))
    await store.send(.pageResponse(generation: 9, page: 2, .success(response)))
    await store.finish()
    XCTAssertEqual(store.state.inFlightPage, 1)
    XCTAssertTrue(store.state.items.isEmpty)
  }

  func testMalformedOrFailedPageCannotReconcileReminders() async {
    for metadata in [Page<Race>.Metadata(page: 2, per: 5, total: 1), .init(page: 1, per: 2, total: 1)] {
      var state = ScheduleList.State(categoryTag: nil)
      state.requestGeneration = 9
      state.inFlightPage = 1
      state.items = [race(0)]
      let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
        $0.sessionReminders.refresh = { _ in
          XCTFail("Malformed metadata must not reconcile reminders")
          return .init(authorization: .allowed, scheduledDates: [:])
        }
      }
      await store.send(.pageResponse(generation: 9, page: 1, .success(.init(items: [race(1)], metadata: metadata)))) {
        $0.inFlightPage = nil
        $0.failedPage = 1
        $0.errorMessage = "A programação recebida está incompleta. Tente novamente."
      }
      await store.finish()
      XCTAssertEqual(store.state.items, state.items)
    }
    var state = ScheduleList.State(categoryTag: nil)
    state.requestGeneration = 9
    state.inFlightPage = 1
    let store = TestStore(initialState: state) { ScheduleList() } withDependencies: {
      $0.sessionReminders.refresh = { _ in
        XCTFail("A failed fetch must not reconcile reminders")
        return .init(authorization: .allowed, scheduledDates: [:])
      }
    }
    await store.send(.pageResponse(generation: 9, page: 1, .failure(URLError(.notConnectedToInternet)))) {
      $0.inFlightPage = nil
      $0.failedPage = 1
      $0.errorMessage = "Não foi possível carregar os horários. Tente novamente."
    }
    await store.finish()
  }

  private func race(_ index: Int, tag: String = "f1") -> Race {
    .init(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
      title: "Round \(index)", shortTitle: "Round \(index)",
      events: [.init(id: UUID(), title: "Race", date: date, isMainEvent: true)],
      category: .init(id: UUID().uuidString, title: tag, tag: tag))
  }
}

private actor ScheduleReminderRecorder {
  var rounds: [[Race]] = []
  func record(_ value: [Race]) { rounds.append(value) }
}
