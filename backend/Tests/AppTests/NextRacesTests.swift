@testable import App
import Fluent
import SQLKit
import XCTVapor

final class NextRacesTests: XCTestCase {
  func testFavoritesArePrioritizedAcrossPageBoundaryWithStableTies() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let favoriteResult = try await Category.query(on: app.db).filter(\.$tag == "f1").first()
    let favorite = try XCTUnwrap(favoriteResult)
    let other = Category(title: "Home fixture \(UUID())", tag: "home-\(UUID())", comment: nil)
    try await other.create(on: app.db)
    let later = Date().addingTimeInterval(86400)
    var favoriteIDs: [UUID] = []
    for index in 1...3 {
      let id = UUID(uuidString: "00000000-0000-0000-0000-00000000000\(index)")!
      favoriteIDs.append(id)
      let race = Race(id: id, title: "Favorite \(index)", earliestEventDate: later, shortTitle: "Favorite \(index)")
      race.$category.id = try favorite.requireID()
      try await race.create(on: app.db)
      let pending = RaceEvent(title: "Pending", date: nil, isMainEvent: true)
      pending.$race.id = id
      pending.scheduledDay = "2027-01-01"
      try await pending.create(on: app.db)
    }
    var otherIDs: [UUID] = []
    for index in 0..<4 {
      let race = Race(title: "Other \(index)", earliestEventDate: later.addingTimeInterval(Double(index - 10) * 3600), shortTitle: "Other")
      race.$category.id = try other.requireID()
      try await race.create(on: app.db)
      otherIDs.append(try race.requireID())
    }
    let cancelled = Race(title: "Cancelled", earliestEventDate: later, shortTitle: "Cancelled")
    cancelled.$category.id = try favorite.requireID(); cancelled.isCancelled = true
    try await cancelled.create(on: app.db)

    var ids: [UUID] = []
    for page in 1...4 {
      try app.test(.GET, "next-races?favorites=f1&page=\(page)&per=2", afterResponse: { response in
        XCTAssertEqual(response.status, .ok)
        let result = try response.content.decode(Page<App.Race>.self)
        XCTAssertEqual(result.metadata.total, 7)
        XCTAssertEqual(result.metadata.page, page)
        ids += try result.items.map { try $0.requireID() }
        if page == 1 {
          let pending = try response.content.decode(PendingPage.self)
          XCTAssertTrue(pending.items.allSatisfy { $0.events.count == 1 && $0.events[0].date == nil })
        }
      })
    }
    XCTAssertEqual(ids, favoriteIDs + otherIDs)
    XCTAssertEqual(Set(ids).count, ids.count)
    try app.test(.GET, "next-races?category=f1&favorites=\(other.tag!)&per=2&page=2", afterResponse: { response in
      let result = try response.content.decode(Page<App.Race>.self)
      XCTAssertEqual(result.metadata.total, 3)
      XCTAssertEqual(result.items.first?.id, favoriteIDs.last)
    })
    try app.test(.GET, "next-races?favorites=f1&page=10&per=2", afterResponse: { response in
      XCTAssertTrue(try response.content.decode(Page<App.Race>.self).items.isEmpty)
    })
  }

  func testOngoingPendingRoundRemainsUpcomingAndInvalidQueriesAreRejected() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let categoryResult = try await Category.query(on: app.db).filter(\.$tag == "f1").first()
    let category = try XCTUnwrap(categoryResult)
    let race = Race(title: "Ongoing", earliestEventDate: Date().addingTimeInterval(-86400), shortTitle: "Ongoing")
    race.$category.id = try category.requireID(); race.scheduleEndDate = Date().addingTimeInterval(86400)
    try await race.create(on: app.db)
    try app.test(.GET, "next-races?per=1&page=1", afterResponse: { response in
      XCTAssertEqual(try response.content.decode(Page<App.Race>.self).items.first?.id, race.id)
    })
    for query in ["page=0", "page=-1", "page=no", "per=0", "per=101", "page=1000001", "favorites=f1,,stock", "favorites=f1%27"] {
      try app.test(.GET, "next-races?\(query)", afterResponse: { XCTAssertEqual($0.status, .badRequest, query) })
    }
  }

  private func makeApp() async throws -> Application {
    guard Environment.get("LANDINHO_TEST_DATABASE") == "1" else { throw XCTSkip("Requires disposable PostgreSQL") }
    let app = Application(.testing)
    do {
      try await configure(app)
      let sql = try XCTUnwrap(app.db as? any SQLDatabase)
      try await sql.raw("TRUNCATE race_event, race, chat, schedule_import CASCADE").run()
      return app
    } catch { app.shutdown(); throw error }
  }
}

private struct PendingPage: Content {
  let items: [Round]
  struct Round: Codable { let events: [Session] }
  struct Session: Codable { let date: String? }
}
