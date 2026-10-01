@testable import App
import Fluent
import SQLKit
import XCTVapor

final class AppTests: XCTestCase {
  func testOfficialPendingTimesIgnoreNumericPlaceholders() throws {
    let meeting = try FormulaOneProvider.parseMeeting(html: fixture("pending"), sourceURL: "https://www.formula1.com/en/racing/2027/bahrain")
    XCTAssertEqual(meeting.id, "1310")
    XCTAssertEqual(meeting.sessions.count, 5)
    XCTAssertTrue(meeting.sessions.allSatisfy { $0.date == nil })
    XCTAssertEqual(meeting.sessions.first?.scheduledDay, "2027-03-12")
  }

  func testConfirmedTimesUseSourceOffsetAndStableIdentity() throws {
    let html = try fixture("confirmed")
    let meeting = try FormulaOneProvider.parseMeeting(html: html, sourceURL: "https://www.formula1.com/en/racing/2026/singapore")
    XCTAssertEqual(meeting.id, "1296")
    XCTAssertEqual(meeting.sessions.first?.date, ScheduleDates.parse("2026-10-09T08:30:00Z"))
    let renamed = try FormulaOneProvider.parseMeeting(html: html.replacingOccurrences(of: "Practice 1", with: "Renamed practice"), sourceURL: meeting.sourceURL)
    XCTAssertEqual(meeting.sessions.map(\.id), renamed.sessions.map(\.id))
  }

  func testTestingAndMalformedPayload() throws {
    let meeting = try FormulaOneProvider.parseMeeting(html: fixture("testing"), sourceURL: "https://www.formula1.com/en/racing/2027/testing")
    XCTAssertFalse(meeting.sessions.isEmpty)
    XCTAssertThrowsError(try FormulaOneProvider.parseMeeting(html: "<html>Maintenance</html>", sourceURL: meeting.sourceURL))
    XCTAssertEqual(FormulaOneProvider.meetingPaths(in: #"<a href="/en/racing/2027/pre-season-testing">Testing</a>"#), ["/en/racing/2027/pre-season-testing"])
    XCTAssertEqual(FormulaOneProvider.seasonYears(in: #"<a href="/en/racing/2027">2027</a>"#), [2027])
  }

  func testDiscoversPublishedNextSeasonWithoutNavigationLink() async throws {
    var requested: [Int] = []
    let paths = try await FormulaOneProvider.calendarPaths(startingWith: 2026) { year in
      requested.append(year)
      switch year {
      case 2026: return #"<a href="/en/racing/2026/singapore">Singapore</a>"#
      case 2027: return #"<a href="/en/racing/2027/bahrain">Bahrain</a><a href="/en/racing/2027/pre-season-testing">Testing</a>"#
      default: return nil
      }
    }
    XCTAssertEqual(requested, [2026, 2027, 2028])
    XCTAssertEqual(paths.count, 3)
    XCTAssertTrue(paths.contains("/en/racing/2027/pre-season-testing"))
    do {
      _ = try await FormulaOneProvider.calendarPaths(startingWith: 2026) { year in
        if year == 2026 { return #"<a href="/en/racing/2026/singapore">Singapore</a>"# }
        throw Abort(.badGateway)
      }
      XCTFail("A failed discovery was accepted as an unpublished season")
    } catch let error as AbortError { XCTAssertEqual(error.status, .badGateway) }
  }

  func testReimportPreservesIDsOverwritesCorrectionAndRetainsManualAddition() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let meeting = sample()
    _ = try await apply([meeting], category: category, app: app)
    let result = try await RaceEvent.query(on: app.db).filter(\.$sourceID == "session-1").first()
    let original = try XCTUnwrap(result)
    let originalID = try original.requireID()
    original.date = meeting.sessions[0].date?.addingTimeInterval(3600)
    try await original.save(on: app.db)
    let manual = RaceEvent(title: "Manual warm-up", date: Date().addingTimeInterval(7200), isMainEvent: false)
    manual.$race.id = original.$race.id
    try await manual.create(on: app.db)
    let run = try await apply([meeting], category: category, app: app)
    let restored = try await RaceEvent.find(originalID, on: app.db)
    let count = try await RaceEvent.query(on: app.db).count()
    let manualRecord = try await RaceEvent.find(manual.id, on: app.db)
    XCTAssertEqual(restored?.date, meeting.sessions[0].date)
    XCTAssertEqual(count, 2)
    XCTAssertNotNil(manualRecord?.importWarning)
    XCTAssertTrue(run.changes.contains { $0.recordID == originalID && $0.field == "date" && $0.before != $0.after })
    let third = try await apply([meeting], category: category, app: app)
    XCTAssertTrue(third.changes.isEmpty)
  }

  func testAdoptsExistingRecordsAndFlagsAmbiguousMeetings() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let meeting = sample()
    let race = Race(title: meeting.title, earliestEventDate: meeting.startDate, shortTitle: meeting.shortTitle)
    race.$category.id = try category.requireID()
    try await race.create(on: app.db)
    let event = RaceEvent(title: "Treino Livre 1", date: meeting.sessions[0].date, isMainEvent: false)
    event.$race.id = try race.requireID()
    try await event.create(on: app.db)
    _ = try await apply([meeting], category: category, app: app)
    let linkedRace = try await Race.find(race.id, on: app.db)
    let linkedSession = try await RaceEvent.find(event.id, on: app.db)
    XCTAssertEqual(linkedRace?.sourceID, meeting.id)
    XCTAssertEqual(linkedSession?.sourceID, "session-1")
    for title in ["Unknown A", "Unknown B"] {
      let candidate = Race(title: title, earliestEventDate: meeting.startDate, shortTitle: title)
      candidate.$category.id = try category.requireID()
      try await candidate.create(on: app.db)
    }
    let run = try await apply([sample(id: "meeting-2", title: "New source title")], category: category, app: app)
    let count = try await Race.query(on: app.db).count()
    XCTAssertEqual(count, 3)
    XCTAssertTrue(run.issues.contains { $0.sourceID == "meeting-2" && $0.candidates.count == 2 })
  }

  func testPartialImportPendingTimesAndMissingRecords() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let missing = Race(title: "Missing round", earliestEventDate: Date().addingTimeInterval(86400), shortTitle: "Missing")
    missing.$category.id = try category.requireID()
    missing.sourceID = "missing"
    missing.sourceURL = "https://www.formula1.com/en/racing/missing"
    try await missing.create(on: app.db)
    let invalid = SourceMeeting(id: "invalid", title: "Invalid", shortTitle: "Invalid", sourceURL: "https://example.test/invalid",
      startDate: Date().addingTimeInterval(86400), endDate: Date(), isCancelled: false, sessions: [])
    let run = try await apply([sample(id: "pending", pending: true), invalid], category: category, app: app)
    let flagged = try await Race.find(missing.id, on: app.db)
    let events = try await RaceEvent.query(on: app.db).all()
    let count = try await Race.query(on: app.db).count()
    XCTAssertEqual(run.status, "partial")
    XCTAssertNotNil(flagged?.importWarning)
    XCTAssertNil(try XCTUnwrap(events.first).date)
    XCTAssertEqual(events.first?.scheduledDay, "2027-01-01")
    XCTAssertEqual(count, 2)
  }

  func testAlertsExcludePendingAndCancelledSessionsAndRounds() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let race = Race(title: "Active round", earliestEventDate: Date(), shortTitle: "Active")
    race.$category.id = try category.requireID()
    try await race.create(on: app.db)
    for (title, pending, cancelled) in [("Active", false, false), ("Pending", true, false), ("Cancelled", false, true)] {
      let event = RaceEvent(title: title, date: pending ? nil : Date().addingTimeInterval(600), isMainEvent: true)
      event.$race.id = try race.requireID()
      event.isCancelled = cancelled
      try await event.create(on: app.db)
    }
    let cancelled = Race(title: "Cancelled round", earliestEventDate: Date(), shortTitle: "Cancelled")
    cancelled.$category.id = try category.requireID()
    cancelled.isCancelled = true
    try await cancelled.create(on: app.db)
    let event = RaceEvent(title: "Cancelled parent", date: Date().addingTimeInterval(600), isMainEvent: true)
    event.$race.id = try cancelled.requireID()
    try await event.create(on: app.db)
    let chat = Chat(); chat.chatID = "123"; chat.subscribedCategories = ["f1"]
    try await chat.create(on: app.db)
    try app.test(.GET, "upcoming-alerts?threshold=3600", afterResponse: { response in
      XCTAssertEqual(response.status, .ok)
      XCTAssertEqual(try response.content.decode([AlertItem].self).map(\.eventTitle), ["Active"])
    })
  }

  func testManualSavePreservesSourceIdentityAndAllowsPendingTime() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    _ = try await apply([sample()], category: category, app: app)
    let result = try await RaceEvent.query(on: app.db).first()
    let event = try XCTUnwrap(result)
    let request = UpdateEventsHandler.SaveEventListRequest(raceID: event.$race.id.uuidString, events: [
      .init(id: try event.requireID(), title: "Manual edit", date: nil, isMainEvent: false, isCancelled: false)
    ])
    try app.test(.POST, "events", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
      try $0.content.encode(request)
    }, afterResponse: { response in
      XCTAssertEqual(response.status, .ok)
    })
    let saved = try await RaceEvent.find(event.id, on: app.db)
    XCTAssertEqual(saved?.sourceID, "session-1")
    XCTAssertEqual(saved?.title, "Manual edit")
    XCTAssertNil(saved?.date)
  }

  func testRefreshConfigurationHistoryAndWeeklyDueGuard() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let meeting = sample()
    app.scheduleImporter = ScheduleImporter(providers: [StubProvider(snapshot: .init(meetings: [meeting], discoveredURLs: [meeting.sourceURL], issues: []))])
    try app.test(.PATCH, "import-settings", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
      try $0.content.encode(UpdateImportSettingsHandler.Input(categoryTag: "f1", enabled: true, intervalDays: 7))
    }, afterResponse: { XCTAssertEqual($0.status, .ok) })
    try app.test(.POST, "import-refresh", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
      try $0.content.encode(RefreshImportHandler.Input(categoryTag: "f1"))
    }, afterResponse: { response in
      XCTAssertEqual(response.status, .ok)
      XCTAssertEqual(try response.content.decode(ImportRun.self).status, "completed")
    })
    let category = try await f1(app)
    let next = try XCTUnwrap(category.nextImportAt)
    let last = try XCTUnwrap(category.lastImportAt)
    XCTAssertEqual(next.timeIntervalSince(last), 7 * 86400, accuracy: 1)
    do {
      _ = try await app.scheduleImporter.refresh(tag: "f1", trigger: "scheduled", db: app.db, client: app.client)
      XCTFail("Scheduled import ran before its due date")
    } catch let error as AbortError { XCTAssertEqual(error.status, .conflict) }
    try app.test(.GET, "imports?category=f1&per=1", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
    }, afterResponse: { response in
      XCTAssertEqual(response.status, .ok)
      XCTAssertEqual(try response.content.decode(Page<ImportRun>.self).items.count, 1)
    })
  }

  func testCancellationRetainsRecordsAndPublishesDiff() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let meeting = sample()
    _ = try await apply([meeting], category: category, app: app)
    let result = try await Race.query(on: app.db).first()
    let original = try XCTUnwrap(result)
    let cancelled = SourceMeeting(id: meeting.id, title: meeting.title, shortTitle: meeting.shortTitle,
      sourceURL: meeting.sourceURL, startDate: meeting.startDate, endDate: meeting.endDate, isCancelled: true,
      sessions: meeting.sessions.map { .init(id: $0.id, title: $0.title, date: $0.date, scheduledDay: $0.scheduledDay, isMainEvent: $0.isMainEvent, isCancelled: true) })
    let run = try await apply([cancelled], category: category, app: app)
    let saved = try await Race.find(original.id, on: app.db)
    let events = try await RaceEvent.query(on: app.db).all()
    let upcoming = try await upcomingRaces(on: app.db).all()
    XCTAssertEqual(saved?.isCancelled, true)
    XCTAssertEqual(events.count, 1)
    XCTAssertTrue(events.allSatisfy(\.isCancelled))
    XCTAssertTrue(upcoming.isEmpty)
    XCTAssertEqual(run.changes.filter { $0.field == "isCancelled" && $0.after == "true" }.count, 2)
  }

  func testFailedFetchRetainsLastGoodScheduleAndRecordsFailure() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let meeting = sample()
    _ = try await apply([meeting], category: category, app: app)
    let importer = ScheduleImporter(providers: [FailingProvider()])
    let run = try await importer.refresh(tag: "f1", trigger: "manual", db: app.db, client: app.client)
    let events = try await RaceEvent.query(on: app.db).all()
    let races = try await Race.query(on: app.db).all()
    XCTAssertEqual(run.status, "failed")
    XCTAssertTrue(run.changes.isEmpty)
    XCTAssertEqual(run.issues.count, 1)
    XCTAssertEqual(events.first?.date, meeting.sessions.first?.date)
    XCTAssertNil(events.first?.importWarning)
    XCTAssertNil(races.first?.importWarning)
  }

  func testCategoryLockRejectsOverlapAndReleasesAfterFailure() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let importer = ScheduleImporter()
    do {
      try await importer.withLock(tag: "f1", db: app.db) { _ in
        do {
          _ = try await importer.refresh(tag: "f1", trigger: "manual", db: app.db, client: app.client)
          XCTFail("Overlapping import acquired the category lock")
        } catch let error as AbortError { XCTAssertEqual(error.status, .conflict) }
        throw Abort(.badRequest)
      }
      XCTFail("Expected operation failure")
    } catch let error as AbortError { XCTAssertEqual(error.status, .badRequest) }
    let acquired = try await importer.withLock(tag: "f1", db: app.db) { _ in true }
    XCTAssertTrue(acquired)
    let count = try await ImportRun.query(on: app.db).count()
    XCTAssertEqual(count, 0)
  }

  func testAdminResolvesAmbiguousMatchAndRejectsStaleChoice() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let category = try await f1(app)
    let meeting = sample()
    var candidates: [Race] = []
    for title in ["Candidate A", "Candidate B"] {
      let race = Race(title: title, earliestEventDate: meeting.startDate, shortTitle: title)
      race.$category.id = try category.requireID()
      try await race.create(on: app.db)
      candidates.append(race)
    }
    let run = try await apply([meeting], category: category, app: app)
    let index = try XCTUnwrap(run.issues.firstIndex { $0.sourceID == meeting.id })
    for (candidateIndex, expected) in [(0, HTTPStatus.ok), (1, .conflict)] {
      let input = ResolveImportMatchHandler.Input(runID: try run.requireID(), issueIndex: index, recordID: try candidates[candidateIndex].requireID())
      try app.test(.POST, "import-match", beforeRequest: {
        $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
        try $0.content.encode(input)
      }, afterResponse: {
        XCTAssertEqual($0.status, expected)
      })
    }
    _ = try await apply([meeting], category: category, app: app)
    let linked = try await Race.find(candidates[0].id, on: app.db)
    let count = try await Race.query(on: app.db).count()
    XCTAssertEqual(linked?.sourceID, meeting.id)
    XCTAssertEqual(linked?.title, meeting.title)
    XCTAssertEqual(count, 2)
  }

  func testProtectedCategoryRoundEditsPreservePublicSchedulesAndSubscriptions() async throws {
    let app = try await makeApp(); defer { app.shutdown() }
    let identity = UUID().uuidString
    let input = UploadCategoryHandler.UploadCategoryRequest(title: "Access test \(identity)", categoryTag: "admin-access-\(identity)", comment: nil, color: nil)
    let count = try await Category.query(on: app.db).count()
    try app.test(.POST, "category", beforeRequest: { try $0.content.encode(input) }, afterResponse: {
      XCTAssertEqual($0.status, .unauthorized)
    })
    let unauthorizedCount = try await Category.query(on: app.db).count()
    XCTAssertEqual(unauthorizedCount, count)
    try app.test(.POST, "category", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
      try $0.content.encode(input)
    }, afterResponse: { XCTAssertEqual($0.status, .ok) })

    let round = UploadRaceHandler.UploadRaceRequest(title: "Access test round", shortTitle: "Access test", categoryTag: input.categoryTag,
      events: [.init(title: "Race", date: Date().addingTimeInterval(86400), isMainEvent: true)], earliestEventDate: nil)
    try app.test(.POST, "race", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
      try $0.content.encode(round)
    }, afterResponse: { XCTAssertEqual($0.status, .ok) })
    let category = try await Category.query(on: app.db).filter(\.$tag == input.categoryTag).first()
    let categoryID = try XCTUnwrap(category?.id)
    let race = try await Race.query(on: app.db).filter(\.$category.$id == categoryID).first()
    let raceID = try XCTUnwrap(race?.id)
    let update = UpdateRaceHandler.UpdateRaceRequest(id: raceID.uuidString, title: "Corrected round", shortTitle: "Access test")
    try app.test(.PATCH, "race", beforeRequest: { try $0.content.encode(update) }, afterResponse: {
      XCTAssertEqual($0.status, .unauthorized)
    })
    let unchanged = try await Race.find(raceID, on: app.db)
    XCTAssertEqual(unchanged?.title, round.title)
    try app.test(.PATCH, "race", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
      try $0.content.encode(update)
    }, afterResponse: { XCTAssertEqual($0.status, .ok) })

    for path in ["category", "race?tag=\(input.categoryTag)", "events?id=\(raceID)",
      "next-race?argument=\(input.categoryTag)", "next-races?category=\(input.categoryTag)", "upcoming-alerts"] {
      try app.test(.GET, path, afterResponse: {
        XCTAssertEqual($0.status, .ok, path)
        for privateField in ["importProvider", "importIntervalDays", "importsEnabled", "nextImportAt", "lastImportAt"] {
          XCTAssertFalse($0.body.string.contains("\"\(privateField)\""), "Private setting exposed by \(path)")
        }
      })
    }
    try app.test(.GET, "import-settings?category=f1", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: "integration-test-only")
    }, afterResponse: {
      XCTAssertEqual($0.status, .ok)
      XCTAssertEqual(try $0.content.decode(ImportSettings.self).provider, "official-f1")
      XCTAssertEqual(try $0.content.decode(ImportSettings.self).intervalDays, 7)
    })
    let subscription = SubscriptionRequest(chatID: "auth-public-test", categoryTag: input.categoryTag)
    try app.test(.POST, "subscribe", beforeRequest: { try $0.content.encode(subscription) }, afterResponse: {
      XCTAssertEqual($0.status, .ok)
    })
    try app.test(.GET, "subscriptions/auth-public-test", afterResponse: {
      XCTAssertEqual($0.status, .ok)
      XCTAssertEqual(try $0.content.decode(SubscriptionResponse.self).subscribedCategories, [input.categoryTag])
    })
    try app.test(.DELETE, "subscribe", beforeRequest: { try $0.content.encode(subscription) }, afterResponse: {
      XCTAssertEqual($0.status, .ok)
      XCTAssertEqual(try $0.content.decode(SubscriptionResponse.self).subscribedCategories, [])
    })
  }

  private func fixture(_ name: String) throws -> String {
    let url = try XCTUnwrap(Bundle.module.url(forResource: "f1-" + name, withExtension: "html", subdirectory: "Fixtures"))
    return try String(contentsOf: url)
  }

  private func makeApp() async throws -> Application {
    guard Environment.get("LANDINHO_TEST_DATABASE") == "1" else { throw XCTSkip("Set LANDINHO_TEST_DATABASE=1 with a disposable PostgreSQL database") }
    let app = Application(.testing)
    do {
      try await configure(app, adminPassword: "integration-test-only")
      let sql = try XCTUnwrap(app.db as? any SQLDatabase)
      try await sql.raw("TRUNCATE race_event, race, chat, schedule_import CASCADE").run()
      let category = try await f1(app)
      category.lastImportAt = nil; category.nextImportAt = Date(); category.importIntervalDays = 7
      try await category.save(on: app.db)
      return app
    } catch { app.shutdown(); throw error }
  }

  private func f1(_ app: Application) async throws -> App.Category {
    let result = try await Category.query(on: app.db).filter(\.$tag == "f1").first()
    return try XCTUnwrap(result)
  }

  private func apply(_ meetings: [SourceMeeting], category: App.Category, app: Application) async throws -> ImportRun {
    let run = ImportRun(categoryTag: "f1", provider: "official-f1", trigger: "test", now: Date())
    try await run.create(on: app.db)
    try await ScheduleImporter().apply(snapshot: .init(meetings: meetings, discoveredURLs: Set(meetings.map(\.sourceURL)), issues: []), category: category, run: run, db: app.db, now: Date())
    return run
  }

  private func sample(id: String = "meeting-1", title: String = "Test Grand Prix", pending: Bool = false) -> SourceMeeting {
    let start = Date(timeIntervalSince1970: floor(Date().timeIntervalSince1970)).addingTimeInterval(86400)
    return .init(id: id, title: title, shortTitle: title, sourceURL: "https://www.formula1.com/en/racing/" + id,
      startDate: start, endDate: start.addingTimeInterval(2 * 86400), isCancelled: false,
      sessions: [.init(id: "session-1", title: "Practice 1", date: pending ? nil : start.addingTimeInterval(3600), scheduledDay: "2027-01-01", isMainEvent: false, isCancelled: false)])
  }
}

private struct StubProvider: ScheduleProvider {
  let id = "official-f1"
  let categoryTag = "f1"
  let snapshot: ScheduleSnapshot
  func fetch(client: Client, now: Date) async throws -> ScheduleSnapshot { snapshot }
}

private struct FailingProvider: ScheduleProvider {
  let id = "official-f1"
  let categoryTag = "f1"
  func fetch(client: Client, now: Date) async throws -> ScheduleSnapshot { throw Abort(.badGateway, reason: "Source unavailable") }
}
