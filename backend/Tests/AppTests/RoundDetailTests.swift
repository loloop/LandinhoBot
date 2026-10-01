@testable import App
import Fluent
import XCTVapor

final class RoundDetailTests: XCTestCase {
  func testMalformedIDIsRejectedBeforeDatabaseAccess() throws {
    let app = Application(.testing)
    defer { app.shutdown() }
    RoundDetailHandler().register(in: app)
    for id in ["bad-id", "4caebfb4c66946f1b74ead391517f373", "00000000-0000-0000-0000-00000000000Z"] {
      try app.test(.GET, "rounds/" + id) { XCTAssertEqual($0.status, .badRequest) }
    }
  }

  func testPublicReadIncludesCategoryPendingSessionsAndPastCancelledRound() async throws {
    guard Environment.get("LANDINHO_TEST_DATABASE") == "1" else {
      throw XCTSkip("Set LANDINHO_TEST_DATABASE=1 with a disposable PostgreSQL database")
    }
    let app = Application(.testing)
    defer { app.shutdown() }
    try await configure(app)
    let category = Category(title: "Read test", tag: "read-" + UUID().uuidString, comment: nil)
    try await category.create(on: app.db)
    let round = Race(title: "Past cancelled round", earliestEventDate: .distantPast, shortTitle: "Past")
    round.$category.id = try category.requireID()
    round.isCancelled = true
    try await round.create(on: app.db)
    let session = RaceEvent(title: "Pending session", date: nil, isMainEvent: true)
    session.$race.id = try round.requireID()
    session.scheduledDay = "2026-01-01"
    try await session.create(on: app.db)
    try app.test(.GET, "rounds/" + round.requireID().uuidString) { response in
      XCTAssertEqual(response.status, .ok)
      let body = try response.content.decode(Round.self)
      XCTAssertEqual(body.id, round.id)
      XCTAssertEqual(body.category.tag, category.tag)
      XCTAssertTrue(body.isCancelled)
      XCTAssertEqual(body.events.count, 1)
      XCTAssertEqual(body.events.first?.id, session.id)
      XCTAssertNil(body.events.first?.date)
      XCTAssertEqual(body.events.first?.scheduledDay, "2026-01-01")
    }
    try app.test(.GET, "rounds/" + UUID().uuidString) { XCTAssertEqual($0.status, .notFound) }
  }

  private struct Round: Content {
    let id: UUID
    let category: CategoryPayload
    let isCancelled: Bool
    let events: [Session]
    struct CategoryPayload: Content { let tag: String }
    struct Session: Content { let id: UUID; let date: Date?; let scheduledDay: String? }
  }
}
