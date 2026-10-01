import Foundation
import XCTest
import LandinhoFoundation
@testable import AppClipFeature

final class ClipDayLabelTests: XCTestCase {
  private func session(date: Date? = nil, day: String? = nil) -> RaceEvent {
    .init(id: UUID(), title: "Corrida", date: date, isMainEvent: true, scheduledDay: day)
  }

  func testConfirmedAndPendingDaysHaveTheSameLocalizedMonthName() {
    let date = ISO8601DateFormatter().date(from: "2026-10-11T12:00:00Z")!
    for locale in [Locale(identifier: "en_US"), Locale(identifier: "pt_BR")] {
      let confirmed = ClipDayLabel.label(for: session(date: date), locale: locale,
        timeZone: TimeZone(secondsFromGMT: 0)!)
      let pending = ClipDayLabel.label(for: session(day: "2026-10-11"), locale: locale)
      XCTAssertEqual(confirmed, pending)
      XCTAssertFalse(confirmed.contains("/"))
      XCTAssertTrue(confirmed.contains("11"))
    }
  }

  func testKnownInstantUsesDeviceTimeZoneButSourceDayDoesNotShift() {
    let locale = Locale(identifier: "en_US")
    let zone = TimeZone(identifier: "America/Los_Angeles")!
    let date = ISO8601DateFormatter().date(from: "2026-10-11T00:30:00Z")!
    XCTAssertEqual(ClipDayLabel.label(for: session(date: date), locale: locale, timeZone: zone), "Oct 10")
    XCTAssertEqual(ClipDayLabel.label(for: session(day: "2026-10-11"), locale: locale, timeZone: zone), "Oct 11")
  }

  func testInvalidSourceDaysArePendingAndLeapDayIsValid() {
    for value in ["2026-02-29", "2026-13-01", "2026-00-01", "2026-10-32", "0000-01-01",
      "2026-1-01", "2026-10-11T00:00:00Z", "2026-10-11-extra", ""] {
      XCTAssertEqual(ClipDayLabel.label(for: session(day: value)), "Data pendente", value)
    }
    XCTAssertEqual(ClipDayLabel.label(for: session(day: "2028-02-29"), locale: Locale(identifier: "en_US")), "Feb 29")
    XCTAssertEqual(ClipDayLabel.label(for: session()), "Data pendente")
  }
}
