import XCTest
@testable import LandinhoFoundation

final class UpcomingSessionQueryTests: XCTestCase {
  private let now = ISO8601DateFormatter().date(from: "2026-10-01T12:00:00Z")!
  private let category = RaceCategory(id: "f1", title: "Fórmula 1", tag: "f1")

  private func session(_ offset: TimeInterval?, main: Bool = true, cancelled: Bool = false, day: String? = nil) -> RaceEvent {
    RaceEvent(id: UUID(), title: main ? "Corrida" : "Treino livre", date: offset.map { now.addingTimeInterval($0) }, isMainEvent: main, isCancelled: cancelled, scheduledDay: day)
  }

  private func round(_ sessions: [RaceEvent], category: RaceCategory? = nil, cancelled: Bool = false) -> Race {
    Race(id: UUID(), title: "Grande Prêmio de São Paulo", shortTitle: "São Paulo", events: sessions, category: category ?? self.category, isCancelled: cancelled)
  }

  func testMainRaceComparedAcrossAllRoundsAndNotRoundOrder() {
    let laterRace = round([session(10, main: false), session(500)])
    let earlierRace = round([session(100), session(-5)])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [laterRace, earlierRace], now: now), .scheduled(round: earlierRace, session: earlierRace.events[0]))
  }

  func testSessionQueryIncludesPracticeAndQualifying() {
    let race = round([session(300), session(50, main: false)])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [race], now: now, mainSessionsOnly: false), .scheduled(round: race, session: race.events[1]))
  }

  func testCategoryFilterDoesNotReturnAnotherCalendar() {
    let selected = round([session(500)])
    let other = round([session(100)], category: RaceCategory(id: "stock", title: "Stock Car", tag: "stock"))
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [other, selected], now: now, categoryTag: "f1"), .scheduled(round: selected, session: selected.events[0]))
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [other, selected], now: now, categoryTag: "missing"), .noUpcomingSession)
  }

  func testCancelledRoundsAndSessionsCannotBeNext() {
    let cancelledRound = round([session(10)], cancelled: true)
    let race = round([session(20, cancelled: true), session(100)])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [cancelledRound, race], now: now), .scheduled(round: race, session: race.events[1]))
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [cancelledRound, round([session(20, cancelled: true)])], now: now), .cancelled)
  }

  func testStartedSessionAndEmptyCalendarReturnNoUpcomingSession() {
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [], now: now), .noUpcomingSession)
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [round([session(0), session(-1)])], now: now), .noUpcomingSession)
  }

  func testRoundWithoutPublishedSessionsReturnsPending() {
    let race = round([])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [race], now: now), .pending(round: race, session: nil))
  }

  func testPendingDayCannotBeSilentlySkippedForLaterConfirmedStart() {
    let race = round([session(3600), session(nil, day: "2026-10-01")])
    let answer = UpcomingSessionQuery.answer(rounds: [race], now: now)
    XCTAssertEqual(answer, .pending(round: race, session: race.events[1]))
    XCTAssertTrue(answer.message().contains("01/10/2026"))
    XCTAssertTrue(answer.message().contains("horário pendente"))
    XCTAssertFalse(answer.message().contains("00:00"))
  }

  func testLaterPendingDayDoesNotHideEarlierConfirmedSession() {
    let race = round([session(nil, day: "2026-10-03"), session(3600)])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [race], now: now), .scheduled(round: race, session: race.events[1]))
  }

  func testPendingDayExpiresOnlyOnceFinishedInEveryTimeZone() {
    let race = round([session(nil, day: "2026-09-30")])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [race], now: now.addingTimeInterval(-1)), .pending(round: race, session: race.events[0]))
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [race], now: now), .noUpcomingSession)
  }

  func testInvalidOrMissingPublishedDayRemainsUnknown() {
    for day in [nil, "2026-02-30", "2026-1-1"] as [String?] {
      let race = round([session(nil, day: day), session(1000)])
      XCTAssertEqual(UpcomingSessionQuery.answer(rounds: [race], now: now), .pending(round: race, session: race.events[0]))
    }
  }

  func testAnswerIncludesDateAndUsesRequestedTimeZone() {
    let race = round([session(3 * 3600)])
    let answer = UpcomingSessionQuery.answer(rounds: [race], now: now)
    let saoPaulo = answer.message(timeZone: TimeZone(identifier: "America/Sao_Paulo")!)
    let tokyo = answer.message(timeZone: TimeZone(identifier: "Asia/Tokyo")!)
    XCTAssertTrue(saoPaulo.contains("12:00"), saoPaulo)
    XCTAssertTrue(saoPaulo.contains("1 de outubro de 2026"), saoPaulo)
    XCTAssertTrue(tokyo.contains("00:00"), tokyo)
    XCTAssertTrue(tokyo.contains("2 de outubro de 2026"), tokyo)
  }

  func testLoadingFetchesEveryPageBeforeSelectingAnAnswer() async throws {
    let first = round([session(5000)])
    let second = round([session(1000)])
    var requested: [Int] = []
    let rounds = try await UpcomingScheduleLoading.rounds { page in
      requested.append(page)
      return UpcomingSchedulePage(items: [page == 1 ? first : second], metadata: .init(page: page, per: 1, total: 2))
    }
    XCTAssertEqual(requested, [1, 2])
    XCTAssertEqual(UpcomingSessionQuery.answer(rounds: rounds, now: now), .scheduled(round: second, session: second.events[0]))
  }

  func testLoadingFailureDoesNotReturnAPartialCalendar() async {
    enum NetworkError: Error { case offline }
    do {
      _ = try await UpcomingScheduleLoading.rounds { page in
        if page == 2 { throw NetworkError.offline }
        return UpcomingSchedulePage(items: [self.round([self.session(100)])], metadata: .init(page: page, per: 1, total: 2))
      }
      XCTFail("A partial result would give a misleading next-session answer")
    } catch { XCTAssertTrue(error is NetworkError) }
  }

  func testMalformedPaginationDoesNotClaimNoResults() async {
    do {
      _ = try await UpcomingScheduleLoading.rounds { page in
        UpcomingSchedulePage(items: [], metadata: .init(page: page, per: 100, total: 200))
      }
      XCTFail("A missing page should fail the query")
    } catch { XCTAssertTrue(error is UpcomingScheduleLoading.LoadingError) }
  }

  func testShortFinalPageIsRejectedEvenWhenItIsTheFirstPage() async {
    for total in [2, 100] {
      do {
        _ = try await UpcomingScheduleLoading.rounds { page in
          UpcomingSchedulePage(items: [self.round([self.session(100)])], metadata: .init(page: page, per: 100, total: total))
        }
        XCTFail("A truncated final page must not produce an answer")
      } catch { XCTAssertTrue(error is UpcomingScheduleLoading.LoadingError) }
    }
    do {
      _ = try await UpcomingScheduleLoading.rounds { page in
        let items = page == 1 ? [self.round([]), self.round([])] : []
        return UpcomingSchedulePage(items: items, metadata: .init(page: page, per: 2, total: 3))
      }
      XCTFail("A missing last item must not produce an answer")
    } catch { XCTAssertTrue(error is UpcomingScheduleLoading.LoadingError) }
  }

  func testDuplicateRoundIDsWithinOrAcrossPagesAreRejected() async {
    let repeated = round([session(100)])
    for per in [1, 2] {
      do {
        _ = try await UpcomingScheduleLoading.rounds { page in
          UpcomingSchedulePage(items: Array(repeating: repeated, count: per), metadata: .init(page: page, per: per, total: 2))
        }
        XCTFail("Repeated round IDs do not establish a complete calendar")
      } catch { XCTAssertTrue(error is UpcomingScheduleLoading.LoadingError) }
    }
  }

  func testChangedPaginationMetadataIsRejected() async {
    for changed in [UpcomingSchedulePage.Metadata(page: 2, per: 2, total: 2), .init(page: 2, per: 1, total: 3), .init(page: 1, per: 1, total: 2)] {
      do {
        _ = try await UpcomingScheduleLoading.rounds { page in
          UpcomingSchedulePage(items: [self.round([])], metadata: page == 1 ? .init(page: 1, per: 1, total: 2) : changed)
        }
        XCTFail("A changing calendar must fail instead of combining inconsistent pages")
      } catch { XCTAssertTrue(error is UpcomingScheduleLoading.LoadingError) }
    }
  }

  func testLoadingStopsAtFiftyPagesInsteadOfReturningPartialResults() async {
    var requests = 0
    do {
      _ = try await UpcomingScheduleLoading.rounds { page in
        requests += 1
        return UpcomingSchedulePage(items: [self.round([])], metadata: .init(page: page, per: 1, total: 51))
      }
      XCTFail("A calendar beyond the limit must not produce an answer")
    } catch { XCTAssertTrue(error is UpcomingScheduleLoading.LoadingError) }
    XCTAssertEqual(requests, 50)
  }
}
