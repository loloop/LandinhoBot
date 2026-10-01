@_spi(Internal) import APIClient
import ComposableArchitecture
import Foundation
import LandinhoFoundation
@_spi(Internal) import MockAPIClient
@testable import ScheduleList
import XCTest

final class MockAPIClientTests: XCTestCase {
  @MainActor
  func testScheduleReducerLoadsThroughTheInjectedMock() async throws {
    let service = MockAPIClientService()
    let page = try await request(Page<Race>.self, from: service, endpoint: "next-races",
      query: ["category": "f1", "page": "0", "per": "5"])
    let store = TestStore(initialState: ScheduleList.State(categoryTag: "f1")) {
      ScheduleList()
    } withDependencies: {
      $0.apiRequester = service
    }
    await store.send(.onAppear)
    await store.receive { action in
      if case .racesRequest(.request) = action { return true }
      return false
    } assert: {
      $0.racesState.response = .loading
    }
    await store.receive(.racesRequest(.response(.finished(.success(page))))) {
      $0.racesState.response = .finished(.success(page))
    }
  }

  func testScheduleSupportsFilteringPaginationAndPendingTimes() async throws {
    let service = MockAPIClientService()
    let page = try await request(Page<Race>.self, from: service, endpoint: "next-races", query: ["category": "f1", "page": "0", "per": "1"])
    XCTAssertEqual(page.items.count, 1)
    XCTAssertEqual(page.items.first?.category.tag, "f1")
    XCTAssertEqual(page.metadata.page, 1)
    XCTAssertEqual(page.metadata.total, 2)

    let next = try await request(Page<Race>.self, from: service, endpoint: "next-races", query: ["category": "f1", "page": "2", "per": "1"])
    XCTAssertNil(next.items.first?.events.first?.date)
    XCTAssertNotNil(next.items.first?.events.first?.scheduledDay)
    let widget = try await request(Race.self, from: service, endpoint: "next-race", query: ["category": "stock-car"])
    XCTAssertEqual(widget.category.tag, "stock-car")
    XCTAssertTrue(widget.events.contains(where: \.isCancelled))
  }

  func testCategoryAndRaceEditsPersistOnlyInTheirServiceInstance() async throws {
    let service = MockAPIClientService()
    let category = try await request(RaceCategory.self, from: service, endpoint: "category", method: "POST",
      body: ["title": "IndyCar", "categoryTag": "indy", "comment": "Demo"])
    let edited = RaceCategory(id: category.id, title: "IndyCar Series", tag: "indy", comment: "Demo")
    let encoded = try JSONEncoder().encode(edited)
    let saved = try await service.request(RaceCategory.self, endpoint: "category", method: "PATCH", data: encoded, queryItems: [], headers: [:])
    XCTAssertEqual(saved, edited)

    let race = try await request(Race.self, from: service, endpoint: "race", method: "POST",
      body: ["title": "Indianapolis 500", "shortTitle": "Indy 500", "categoryTag": "indy"])
    let races = try await request([Race].self, from: service, endpoint: "race", query: ["tag": "indy"])
    XCTAssertEqual(races.map(\.id), [race.id])
    XCTAssertEqual(races.first?.category, edited)

    let fresh = try await request([RaceCategory].self, from: MockAPIClientService(), endpoint: "category")
    XCTAssertFalse(fresh.contains(where: { $0.tag == "indy" }))
  }

  func testSavingEventsUpdatesTheScheduleAndPruningRemovesPastRaces() async throws {
    let service = MockAPIClientService()
    let race = try await request(Race.self, from: service, endpoint: "next-race", query: ["category": "stock-car"])
    let past = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-86400))
    let events = try await request([RaceEvent].self, from: service, endpoint: "events", method: "POST",
      body: ["raceID": race.id.uuidString, "events": [["title": "Corrida", "date": past, "isMainEvent": true]]])
    XCTAssertEqual(events.count, 1)
    let loaded = try await request([RaceEvent].self, from: service, endpoint: "events", query: ["id": race.id.uuidString])
    XCTAssertEqual(loaded, events)
    let schedule = try await request(Page<Race>.self, from: service, endpoint: "next-races", query: ["category": "stock-car"])
    XCTAssertTrue(schedule.items.isEmpty)
    let remaining = try await request([Race].self, from: service, endpoint: "prune-race", query: ["tag": "stock-car"])
    XCTAssertTrue(remaining.isEmpty)
  }

  func testRacePatchAcceptsTheAppsReferenceDateEncoding() async throws {
    let service = MockAPIClientService()
    let race = try await request(Race.self, from: service, endpoint: "next-race")
    let date = Date(timeIntervalSince1970: 2000000000)
    let summary = try await request(RaceSummary.self, from: service, endpoint: "race", method: "PATCH",
      body: ["id": race.id.uuidString, "title": "Edited", "shortTitle": "Edit", "earliestEventDate": date.timeIntervalSinceReferenceDate])
    XCTAssertEqual(summary.title, "Edited")
    XCTAssertEqual(summary.earliestEventDate, date)
  }

  func testImportSettingsAndRefreshProduceInMemoryHistory() async throws {
    let service = MockAPIClientService()
    let saved = try await request(Settings.self, from: service, endpoint: "import-settings", method: "PATCH",
      body: ["categoryTag": "f1", "enabled": false, "intervalDays": 14])
    XCTAssertFalse(saved.enabled)
    XCTAssertEqual(saved.intervalDays, 14)
    let run = try await request(Run.self, from: service, endpoint: "import-refresh", method: "POST", body: ["categoryTag": "f1"])
    XCTAssertEqual(run.status, "completed")
    let history = try await request(History.self, from: service, endpoint: "imports", query: ["category": "f1"])
    XCTAssertEqual(history.items.map(\.id), [run.id])
    XCTAssertEqual(history.metadata.total, 1)
    let settings = try await request(Settings.self, from: service, endpoint: "import-settings", query: ["category": "f1"])
    XCTAssertNotNil(settings.lastImportAt)
    XCTAssertNil(settings.nextImportAt)
  }

  func testUnsupportedRouteAndInvalidImportSettingsThrowMockErrors() async throws {
    let service = MockAPIClientService()
    do {
      _ = try await request(Race.self, from: service, endpoint: "unknown")
      XCTFail("An unknown route must fail instead of falling back to live networking")
    } catch MockError.unsupportedRoute(let method, let endpoint) {
      XCTAssertEqual(method, "GET")
      XCTAssertEqual(endpoint, "unknown")
    }
    do {
      _ = try await request(Settings.self, from: service, endpoint: "import-settings", method: "PATCH",
        body: ["categoryTag": "f1", "enabled": true, "intervalDays": 0])
      XCTFail("Invalid settings must fail")
    } catch MockError.invalidBody {}
  }

  func testDefaultTestDependencyDoesNotUseLiveNetworking() async throws {
    let service = withDependencies { $0.context = .test } operation: {
      @Dependency(\.apiRequester) var requester
      return requester
    }
    do {
      _ = try await service.request(Race.self, endpoint: "next-race", method: "GET", data: nil, queryItems: [], headers: [:])
      XCTFail("The default test dependency must cancel requests")
    } catch let error as URLError {
      XCTAssertEqual(error.code, .cancelled)
    }
  }

  private func request<T: Decodable>(
    _ type: T.Type, from service: MockAPIClientService, endpoint: String, method: String = "GET",
    body: [String: Any]? = nil, query: [String: String] = [:]
  ) async throws -> T {
    try await service.request(type, endpoint: endpoint, method: method,
      data: try body.map { try JSONSerialization.data(withJSONObject: $0) },
      queryItems: query.map { URLQueryItem(name: $0.key, value: $0.value) }, headers: [:])
  }

  private struct RaceSummary: Decodable {
    let title: String
    let earliestEventDate: Date?
  }
  private struct Settings: Decodable {
    let enabled: Bool
    let intervalDays: Int
    let lastImportAt: Date?
    let nextImportAt: Date?
  }
  private struct Run: Decodable {
    let id: UUID
    let status: String
  }
  private struct History: Decodable {
    let items: [Run]
    let metadata: Metadata
    struct Metadata: Decodable { let total: Int }
  }
}
