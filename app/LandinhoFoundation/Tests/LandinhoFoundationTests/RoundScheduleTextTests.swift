import XCTest
@testable import LandinhoFoundation

final class RoundScheduleTextTests: XCTestCase {
  private let locale = Locale(identifier: "pt_BR")
  private let saoPaulo = TimeZone(identifier: "America/Sao_Paulo")!

  func testFullScheduleKeepsBotStyleAndIncludesEverySessionInOrder() {
    let text = format(round([
      event("Corrida", date: "2026-10-18T17:00:00Z", isMain: true),
      event("Treino Livre", date: "2026-10-16T13:00:00Z"),
      event("Classificação", date: "2026-10-17T15:00:00Z")
    ], sourceURL: "https://example.com/calendar"))

    XCTAssertEqual(text, """
    Formula 1
    Grande Prêmio de São Paulo

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    16/10/2026 às 10:00 – Treino Livre
    17/10/2026 às 12:00 – Classificação
    18/10/2026 às 14:00 – Corrida

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    Horários no fuso do dispositivo: America/Sao_Paulo

    Programação oficial: https://example.com/calendar
    """)
  }

  func testDeviceTimezoneChangesTheDayAndTimeTogether() {
    let race = round([event("Corrida", date: "2026-10-18T01:30:00Z")])
    let tokyo = TimeZone(identifier: "Asia/Tokyo")!

    XCTAssertTrue(format(race).contains("17/10/2026 às 22:30 – Corrida"))
    XCTAssertTrue(format(race, timeZone: tokyo).contains("18/10/2026 às 10:30 – Corrida"))
    XCTAssertTrue(format(race, timeZone: tokyo).contains("Horários no fuso do dispositivo: Asia/Tokyo"))
  }

  func testPendingDaysArePreservedWithoutATimeOrTimezoneShift() {
    let race = round([
      event("Classificação", scheduledDay: "2026-10-17"),
      event("Treino", date: "2026-10-17T13:00:00Z"),
      event("Corrida", isMain: true)
    ])
    let text = format(race)

    XCTAssertTrue(text.contains("17/10/2026 às 10:00 – Treino\n17/10/2026 – Horário pendente – Classificação\nData pendente – Horário pendente – Corrida"))
    XCTAssertTrue(format(race, timeZone: TimeZone(identifier: "Pacific/Honolulu")!)
      .contains("17/10/2026 – Horário pendente – Classificação"))
    XCTAssertFalse(text.contains("00:00"))
    XCTAssertTrue(text.contains("Ainda não conseguimos obter todos os horários."))
  }

  func testInvalidPendingDaysStayUnknownAndLeapDaysAreValidated() {
    let text = format(round([
      event("Inválido", scheduledDay: "2026-02-30"),
      event("Incompleto", scheduledDay: "2026-2-03"),
      event("Bissexto", scheduledDay: "2028-02-29")
    ]))

    XCTAssertTrue(text.contains("29/02/2028 – Horário pendente – Bissexto"))
    XCTAssertTrue(text.contains("Data pendente – Horário pendente – Inválido"))
    XCTAssertTrue(text.contains("Data pendente – Horário pendente – Incompleto"))
    XCTAssertFalse(text.contains("30/02"))
  }

  func testCancellationDoesNotAdvertiseAnOldStartOrBecomePending() {
    let text = format(round([
      event("Sprint", date: "2026-10-17T15:00:00Z", isCancelled: true),
      event("Treino", isCancelled: true)
    ]))

    XCTAssertTrue(text.contains("17/10/2026 – Cancelado – Sprint"))
    XCTAssertTrue(text.contains("Data pendente – Cancelado – Treino"))
    XCTAssertFalse(text.contains("12:00"))
    XCTAssertFalse(text.contains("Horário pendente"))
    XCTAssertFalse(text.contains("Ainda não conseguimos"))
  }

  func testRoundCancellationAppliesToEverySessionIncludingUnknownTimes() {
    let text = format(round([
      event("Corrida", date: "2026-10-18T17:00:00Z", isMain: true),
      event("Treino", scheduledDay: "2026-10-16")
    ], isCancelled: true))

    XCTAssertTrue(text.contains("Etapa cancelada"))
    XCTAssertTrue(text.contains("16/10/2026 – Cancelado – Treino"))
    XCTAssertTrue(text.contains("18/10/2026 – Cancelado – Corrida"))
    XCTAssertFalse(text.contains("14:00"))
    XCTAssertFalse(text.contains("Horário pendente"))
    XCTAssertFalse(text.contains("Ainda não conseguimos"))
  }

  func testEmptyRoundReportsPendingScheduleWithoutAnInventedDate() {
    let text = format(round([]))

    XCTAssertTrue(text.contains("Horários pendentes"))
    XCTAssertTrue(text.contains("Ainda não conseguimos obter todos os horários."))
    XCTAssertFalse(text.contains("00:00"))
    XCTAssertTrue(format(round([], isCancelled: true)).contains("Etapa cancelada"))
    XCTAssertFalse(format(round([], isCancelled: true)).contains("Horários pendentes"))
  }

  func testEqualStartsRetainSourceOrderAndDatesUseGregorianYears() {
    let race = round([
      event("Corrida 2", date: "2026-10-18T17:00:00Z"),
      event("Corrida 1", date: "2026-10-18T17:00:00Z")
    ])
    let text = RoundScheduleText.format(race: race, locale: Locale(identifier: "th_TH"), timeZone: saoPaulo)

    XCTAssertTrue(text.contains("18/10/2026 às 14:00 – Corrida 2\n18/10/2026 às 14:00 – Corrida 1"))
  }

  func testDaylightSavingClockChangeKeepsActualStartOrder() {
    let race = round([
      event("Segundo treino", date: "2026-11-01T06:15:00Z"),
      event("Primeiro treino", date: "2026-11-01T05:45:00Z")
    ])
    let text = format(race, timeZone: TimeZone(identifier: "America/New_York")!)

    XCTAssertTrue(text.contains("01/11/2026 às 01:45 – Primeiro treino\n01/11/2026 às 01:15 – Segundo treino"))
  }

  private func format(_ race: Race, timeZone: TimeZone? = nil) -> String {
    RoundScheduleText.format(race: race, locale: locale, timeZone: timeZone ?? saoPaulo)
  }

  private func event(_ title: String, date: String? = nil, isMain: Bool = false,
                     isCancelled: Bool = false, scheduledDay: String? = nil) -> RaceEvent {
    RaceEvent(id: UUID(), title: title, date: date.flatMap { ISO8601DateFormatter().date(from: $0) },
      isMainEvent: isMain, isCancelled: isCancelled, scheduledDay: scheduledDay)
  }

  private func round(_ sessions: [RaceEvent], isCancelled: Bool = false, sourceURL: String? = nil) -> Race {
    Race(id: UUID(), title: "Grande Prêmio de São Paulo", shortTitle: "São Paulo", events: sessions,
      category: .init(id: "f1", title: "Formula 1", tag: "f1"), sourceURL: sourceURL, isCancelled: isCancelled)
  }
}
