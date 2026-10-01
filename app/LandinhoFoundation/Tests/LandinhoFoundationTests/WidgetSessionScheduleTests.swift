import XCTest
@testable import LandinhoFoundation

final class WidgetSessionScheduleTests: XCTestCase {
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  func testPastAndStartingSessionsDisappearAtTheBoundary() {
    let practice = event("Treino", offset: -60)
    let qualifying = event("Classificação", offset: 0)
    let raceSession = event("Corrida", offset: 60, isMain: true)
    let schedule = schedule([raceSession, practice, qualifying])

    XCTAssertEqual(schedule.sessions, [raceSession])
    XCTAssertEqual(schedule.transitionDates, [now, now.addingTimeInterval(60)])
  }

  func testEveryTimelineTransitionDropsOnlyStartsThatHavePassed() {
    let practice = event("Treino", offset: 60)
    let qualifying = event("Classificação", offset: 120)
    let raceSession = event("Corrida", offset: 180, isMain: true)
    let round = round([raceSession, practice, qualifying])
    let dates = WidgetSessionSchedule(race: round, date: now).transitionDates
    let remaining = dates.map { WidgetSessionSchedule(race: round, date: $0).sessions }

    XCTAssertEqual(remaining, [
      [practice, qualifying, raceSession],
      [qualifying, raceSession],
      [raceSession],
      []
    ])
    XCTAssertEqual(WidgetSessionSchedule(race: round, date: dates.last!).emptyState, .noUpcomingSessions)
  }

  func testSimultaneousStartsHaveOneTransitionAndStableOrdering() {
    let first = event("Corrida 1", offset: 60, isMain: true)
    let second = event("Corrida 2", offset: 60, isMain: true)
    let round = round([first, second])

    XCTAssertEqual(schedule([first, second]).sessions, [first, second])
    XCTAssertEqual(schedule([first, second]).transitionDates, [now, now.addingTimeInterval(60)])
    XCTAssertTrue(WidgetSessionSchedule(race: round, date: now.addingTimeInterval(60)).sessions.isEmpty)
  }

  func testPendingTimeRemainsVisibleWithoutInventingATransition() {
    let pending = event("Corrida", offset: nil, isMain: true)
    let practice = event("Treino", offset: 60)

    XCTAssertEqual(schedule([pending, practice]).sessions, [practice, pending])
    XCTAssertEqual(schedule([pending, practice]).transitionDates, [now, now.addingTimeInterval(60)])
    XCTAssertEqual(schedule([pending]).sessions, [pending])
    XCTAssertNil(schedule([pending]).emptyState)
  }

  func testCancelledSessionsNeverSupplyUpcomingStarts() {
    let cancelled = event("Treino", offset: 30, isCancelled: true)
    let cancelledPending = event("Classificação", offset: nil, isCancelled: true)
    let raceSession = event("Corrida", offset: 60, isMain: true)

    XCTAssertEqual(schedule([cancelled, cancelledPending, raceSession]).sessions, [raceSession])
    XCTAssertEqual(schedule([cancelled, cancelledPending, raceSession]).transitionDates, [now, now.addingTimeInterval(60)])
    XCTAssertEqual(schedule([cancelled, cancelledPending]).emptyState, .cancelledSessions)
  }

  func testCancelledRoundHasNoFutureEntriesEvenWithDatedSessions() {
    let round = round([event("Corrida", offset: 60)], isCancelled: true)
    let schedule = WidgetSessionSchedule(race: round, date: now)

    XCTAssertTrue(schedule.sessions.isEmpty)
    XCTAssertEqual(schedule.transitionDates, [now])
    XCTAssertEqual(schedule.emptyState, .cancelledRound)
  }

  func testPracticeFilteringDoesNotLeakAcrossWidgetConfigurations() {
    let practice = event("Treino", offset: 30)
    let raceSession = event("Corrida", offset: 60, isMain: true)
    let round = round([practice, raceSession])
    let mainOnly = WidgetSessionSchedule(race: round, date: now, showNonMainEventSessions: false)
    let allSessions = WidgetSessionSchedule(race: round, date: now)

    XCTAssertEqual(mainOnly.sessions, [raceSession])
    XCTAssertEqual(mainOnly.transitionDates, [now, now.addingTimeInterval(60)])
    XCTAssertEqual(allSessions.sessions, [practice, raceSession])
    XCTAssertEqual(allSessions.transitionDates, [now, now.addingTimeInterval(30), now.addingTimeInterval(60)])
    XCTAssertEqual(round.events, [practice, raceSession])
  }

  func testEmptyReasonsDistinguishUnknownTimesFromCompletedOrFilteredRounds() {
    XCTAssertEqual(schedule([]).emptyState, .pendingTimes)
    XCTAssertEqual(schedule([event("Corrida", offset: -60)]).emptyState, .noUpcomingSessions)
    let practiceOnly = round([event("Treino", offset: 60)])
    XCTAssertEqual(WidgetSessionSchedule(race: practiceOnly, date: now, showNonMainEventSessions: false).emptyState, .noMainSessions)
    XCTAssertEqual(schedule([]).transitionDates, [now])
  }

  func testTwoRoundsChooseTheirOwnNextSession() {
    let first = event("Classificação", offset: 60)
    let second = event("Corrida", offset: 120)

    XCTAssertEqual(schedule([first]).sessions.first, first)
    XCTAssertEqual(schedule([second]).sessions.first, second)
    XCTAssertEqual(schedule([first]).sessions.first, first)
  }

  private func event(_ title: String, offset: TimeInterval?, isMain: Bool = false, isCancelled: Bool = false) -> RaceEvent {
    RaceEvent(id: UUID(), title: title, date: offset.map { now.addingTimeInterval($0) }, isMainEvent: isMain, isCancelled: isCancelled)
  }

  private func round(_ sessions: [RaceEvent], isCancelled: Bool = false) -> Race {
    Race(id: UUID(), title: "São Paulo", shortTitle: "São Paulo", events: sessions,
         category: .init(id: "f1", title: "Formula 1", tag: "f1"), isCancelled: isCancelled)
  }

  private func schedule(_ sessions: [RaceEvent]) -> WidgetSessionSchedule {
    WidgetSessionSchedule(race: round(sessions), date: now)
  }
}
