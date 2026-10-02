import CalendarStore
import Foundation
import LandinhoFoundation
import XCTest

final class CalendarStoreTests: XCTestCase {
  private let date = Date(timeIntervalSince1970: 1_800_000_000)
  private let home = CalendarQuery(category: nil, favorites: [], per: 2)

  func testCategoriesAndCompleteRoundsSurviveReopeningTheDatabase() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "calendar-store-\(UUID())")
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "calendar.sqlite")
    let first = CalendarStore(databaseURL: url)
    let race = round()
    try await first.saveCategories([race.category], date)
    try await first.savePage(home, CalendarPage(items: [race], page: 1, per: 2, total: 1), date)

    let reopened = CalendarStore(databaseURL: url)
    let categories = try await reopened.loadCategories()
    let saved = try await reopened.loadPage(home, 1)
    let detail = try await reopened.loadRound(race.id)
    XCTAssertEqual(categories, SavedCalendar(value: [race.category], updatedAt: date))
    XCTAssertEqual(saved?.value.items, [race])
    XCTAssertEqual(saved?.updatedAt, date)
    XCTAssertEqual(detail, SavedCalendar(value: race, updatedAt: date))
  }

  func testQueriesKeepFavoritesCategoryPageSizeAndServerOrderSeparate() async throws {
    let store = CalendarStore(databaseURL: nil)
    let first = round()
    let second = round()
    let favorites = CalendarQuery(category: nil, favorites: ["stock", "f1"], per: 2)
    let f1 = CalendarQuery(category: "f1", favorites: ["stock"], per: 2)
    let page = CalendarPage(items: [second, first], page: 1, per: 2, total: 4)
    try await store.savePage(favorites, page, date)
    try await store.savePage(f1, CalendarPage(items: [first], page: 1, per: 2, total: 1), date)
    let saved = try await store.loadPage(CalendarQuery(category: nil, favorites: ["f1", "stock"], per: 2), 1)
    XCTAssertEqual(saved?.value.items.map(\.id), [second.id, first.id])
    let category = try await store.loadPage(CalendarQuery(category: "f1", favorites: [], per: 2), 1)
    XCTAssertEqual(category?.value.items, [first])
    let otherFavorites = try await store.loadPage(home, 1)
    let otherPageSize = try await store.loadPage(CalendarQuery(category: nil, favorites: ["f1", "stock"], per: 5), 1)
    let missingPage = try await store.loadPage(favorites, 2)
    XCTAssertNil(otherFavorites)
    XCTAssertNil(otherPageSize)
    XCTAssertNil(missingPage)
  }

  func testFirstPageRefreshInvalidatesLaterPagesAndPersistsAnEmptyCalendar() async throws {
    let store = CalendarStore(databaseURL: nil)
    try await store.savePage(home, CalendarPage(items: [round()], page: 1, per: 2, total: 4), date)
    try await store.savePage(home, CalendarPage(items: [round()], page: 2, per: 2, total: 4), date)
    let nextDate = date.addingTimeInterval(60)
    try await store.savePage(home, CalendarPage(items: [], page: 1, per: 2, total: 0), nextDate)
    let empty = try await store.loadPage(home, 1)
    let oldPage = try await store.loadPage(home, 2)
    XCTAssertEqual(empty?.value.items, [])
    XCTAssertEqual(empty?.value.total, 0)
    XCTAssertEqual(empty?.updatedAt, nextDate)
    XCTAssertNil(oldPage)
    try await store.saveCategories([], nextDate)
    let emptyCategories = try await store.loadCategories()
    XCTAssertEqual(emptyCategories?.value, [])
  }

  func testDetailUpdatesReachStoredPagesAndRemovedRoundsInvalidateTheirPages() async throws {
    let store = CalendarStore(databaseURL: nil)
    let original = round()
    try await store.savePage(home, CalendarPage(items: [original], page: 1, per: 2, total: 1), date)
    let cancelled = round(id: original.id, cancelled: true)
    try await store.saveRound(cancelled, date.addingTimeInterval(60))
    let updated = try await store.loadPage(home, 1)
    XCTAssertEqual(updated?.value.items, [cancelled])
    try await store.removeRound(original.id)
    let detail = try await store.loadRound(original.id)
    let incomplete = try await store.loadPage(home, 1)
    XCTAssertNil(detail)
    XCTAssertNil(incomplete)
  }

  func testDifferentAPISourcesNeverShareSavedCalendars() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "calendar-sources-\(UUID())")
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "calendar.sqlite")
    let first = CalendarStore(databaseURL: url, source: "https://first.example")
    let second = CalendarStore(databaseURL: url, source: "http://localhost:8080")
    let race = round()
    try await first.saveCategories([race.category], date)
    try await first.savePage(home, CalendarPage(items: [race], page: 1, per: 2, total: 1), date)
    let categories = try await second.loadCategories()
    let page = try await second.loadPage(home, 1)
    let detail = try await second.loadRound(race.id)
    XCTAssertNil(categories)
    XCTAssertNil(page)
    XCTAssertNil(detail)
  }

  func testMalformedPageCannotReplaceSavedData() async throws {
    let store = CalendarStore(databaseURL: nil)
    let race = round()
    try await store.savePage(home, CalendarPage(items: [race], page: 1, per: 2, total: 1), date)
    do {
      try await store.savePage(home, CalendarPage(items: [], page: 1, per: 5, total: 0), date)
      XCTFail("A different page size must not replace this query")
    } catch {}
    let saved = try await store.loadPage(home, 1)
    XCTAssertEqual(saved?.value.items, [race])
  }

  func testURLOverridesNeverPersistCredentialsOrUnusedQueryValues() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: "calendar-credentials-\(UUID())")
    defer { try? FileManager.default.removeItem(at: directory) }
    let url = directory.appending(path: "calendar.sqlite")
    let override = CalendarStore(databaseURL: url,
      source: "https://admin:secret-password@EXAMPLE.com:443/calendar/?unused=secret-token#private-fragment")
    let canonical = CalendarStore(databaseURL: url, source: "https://example.com/calendar")
    let race = round()
    try await override.saveCategories([race.category], date)
    try await override.saveRound(race, date)
    let categories = try await canonical.loadCategories()
    let detail = try await canonical.loadRound(race.id)
    XCTAssertEqual(categories?.value, [race.category])
    XCTAssertEqual(detail?.value, race)
    let bytes = try Data(contentsOf: url)
    for secret in ["secret-password", "secret-token", "private-fragment"] {
      XCTAssertNil(bytes.range(of: Data(secret.utf8)))
    }
  }

  func testDelayedWritesCannotRestoreOldPagesOrOverwriteNewerDetails() async throws {
    let store = CalendarStore(databaseURL: nil)
    let original = round()
    let fresh = round(id: original.id, cancelled: true)
    let later = date.addingTimeInterval(60)
    try await store.savePage(home, CalendarPage(items: [original], page: 1, per: 2, total: 4), date)
    try await store.saveRound(fresh, later)
    try await store.saveRound(original, date)
    let detail = try await store.loadRound(original.id)
    XCTAssertEqual(detail?.value, fresh)
    try await store.savePage(home, CalendarPage(items: [], page: 1, per: 2, total: 0), later)
    try await store.savePage(home, CalendarPage(items: [original], page: 2, per: 2, total: 4), date)
    try await store.savePage(home, CalendarPage(items: [original], page: 1, per: 2, total: 4), date)
    let first = try await store.loadPage(home, 1)
    let second = try await store.loadPage(home, 2)
    XCTAssertEqual(first?.value.items, [])
    XCTAssertNil(second)
  }

  private func round(id: UUID = UUID(), cancelled: Bool = false) -> Race {
    Race(id: id, title: "São Paulo", shortTitle: "SP", events: [
      RaceEvent(id: UUID(), title: "Corrida", date: date, isMainEvent: true),
      RaceEvent(id: UUID(), title: "Classificação", date: nil, isMainEvent: false,
        isCancelled: true, scheduledDay: "2027-01-15", sourceURL: "https://example.com/session"),
    ], category: RaceCategory(id: "f1", title: "Formula 1", tag: "f1", comment: "Official calendar",
      color: CategoryColor(red: 240, green: 30, blue: 50)),
      sourceURL: "https://example.com/round", isCancelled: cancelled)
  }
}
