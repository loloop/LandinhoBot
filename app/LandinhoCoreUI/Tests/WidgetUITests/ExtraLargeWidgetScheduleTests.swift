import Foundation
import LandinhoFoundation
import XCTest
@testable import WidgetUI

final class ExtraLargeWidgetScheduleTests: XCTestCase {
  let now = Date(timeIntervalSince1970: 1_800_000_000)

  func testColumnsPreserveChronologicalOrderWithoutRepeatingNextSession() {
    let sessions = (1...10).map { session($0) }
    let schedule = presentation(Array(sessions.reversed()), rows: 3)

    XCTAssertEqual(schedule.nextSession, sessions[0])
    XCTAssertEqual(schedule.columns, [Array(sessions[1...3]), Array(sessions[4...6])])
    XCTAssertEqual(schedule.hiddenSessionCount, 3)
  }

  func testCompactLayoutKeepsBalancedColumnsAndAccountsForEverySession() {
    let sessions = (1...6).map { session($0) }
    let compact = presentation(sessions, rows: 2)
    let expanded = presentation(sessions, rows: 4)

    XCTAssertEqual(compact.columns.map(\.count), [2, 2])
    XCTAssertEqual(compact.hiddenSessionCount, 1)
    XCTAssertEqual(expanded.columns.map(\.count), [3, 2])
    XCTAssertEqual(expanded.columns.flatMap { $0 }, Array(sessions.dropFirst()))
    XCTAssertEqual(expanded.hiddenSessionCount, 0)
  }

  func testExpiredCancelledAndFilteredSessionsDoNotConsumeLayoutCapacity() {
    let past = session(-1)
    let cancelled = session(1, cancelled: true)
    let practice = session(2, main: false)
    let race = session(3)
    let pending = RaceEvent(id: UUID(), title: "Sprint", date: nil, isMainEvent: true, scheduledDay: "2027-01-17")
    let schedule = presentation([pending, past, cancelled, practice, race], showNonMain: false)

    XCTAssertEqual(schedule.nextSession, race)
    XCTAssertEqual(schedule.columns, [[pending]])
    XCTAssertEqual(schedule.hiddenSessionCount, 0)
  }

  func testEmptyCancelledAndSingleSessionRoundsHaveNoColumnsOrHiddenSessions() {
    for schedule in [presentation([]), presentation([session(-1)]), presentation([session(1)], cancelled: true)] {
      XCTAssertNil(schedule.nextSession)
      XCTAssertTrue(schedule.columns.isEmpty)
      XCTAssertEqual(schedule.hiddenSessionCount, 0)
    }
    let only = session(1)
    XCTAssertEqual(presentation([only]).nextSession, only)
    XCTAssertTrue(presentation([only]).columns.isEmpty)
  }

  private func session(_ index: Int, main: Bool = true, cancelled: Bool = false) -> RaceEvent {
    RaceEvent(id: UUID(), title: "Sessão \(index)", date: now.addingTimeInterval(Double(index) * 60), isMainEvent: main, isCancelled: cancelled)
  }

  private func presentation(_ sessions: [RaceEvent], rows: Int = 3, showNonMain: Bool = true, cancelled: Bool = false) -> ExtraLargeWidgetSchedule {
    let race = Race(id: UUID(), title: "São Paulo", shortTitle: "São Paulo", events: sessions,
                    category: .init(id: "f1", title: "Formula 1", tag: "f1"), isCancelled: cancelled)
    return ExtraLargeWidgetSchedule(
      content: WidgetScheduleContent(race: race, referenceDate: now, showNonMainEventSessions: showNonMain), rowsPerColumn: rows)
  }
}
