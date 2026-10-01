import Foundation

/// A read-only answer from the category calendars, shared by Siri and its result snippet.
public enum UpcomingSessionAnswer: Equatable {
  case scheduled(round: Race, session: RaceEvent)
  case pending(round: Race, session: RaceEvent?)
  case cancelled
  case noUpcomingSession

  public func message(categoryTitle: String? = nil, timeZone: TimeZone = .current, locale: Locale = Locale(identifier: "pt_BR")) -> String {
    let category = categoryTitle.map { " de \($0)" } ?? ""
    switch self {
    case .scheduled(let round, let session):
      guard let date = session.date else { return "O horário ainda está pendente." }
      let formatter = DateFormatter()
      formatter.locale = locale
      formatter.timeZone = timeZone
      formatter.dateStyle = .full
      formatter.timeStyle = .short
      let zoneStyle: TimeZone.NameStyle = timeZone.isDaylightSavingTime(for: date) ? .daylightSaving : .standard
      let zone = timeZone.localizedName(for: zoneStyle, locale: locale) ?? timeZone.identifier
      return "\(session.title), \(round.shortTitle), de \(round.category.title), começa em \(formatter.string(from: date)), no fuso \(zone)."
    case .pending(let round, let session):
      let title = session?.title ?? "A programação"
      let day = session?.scheduledDay.flatMap(UpcomingSessionQuery.publishedDayLabel).map { ", prevista para \($0)" } ?? ""
      return "\(title) de \(round.shortTitle), de \(round.category.title)\(day), está com o horário pendente. O calendário ainda não confirma quando começa."
    case .cancelled:
      return "As sessões disponíveis\(category) foram canceladas. Não há um próximo horário confirmado."
    case .noUpcomingSession:
      return "Não encontrei uma próxima sessão\(category) no calendário."
    }
  }
}

public enum UpcomingSessionQuery {
  /// A pending source day has no time zone. Keep it until that day has ended everywhere;
  /// never turn its date into a midnight start or silently skip an earlier possible session.
  public static func answer(rounds: [Race], now: Date, mainSessionsOnly: Bool = true, categoryTag: String? = nil) -> UpcomingSessionAnswer {
    let rounds = rounds.filter { categoryTag == nil || $0.category.tag == categoryTag }
    var candidates: [(date: Date, answer: UpcomingSessionAnswer)] = []
    var sawCancellation = false
    var sawNonCancelledSession = false

    for round in rounds {
      if round.isCancelled {
        sawCancellation = true
        continue
      }
      if round.events.isEmpty {
        candidates.append((.distantPast, .pending(round: round, session: nil)))
      }
      for session in round.events where !mainSessionsOnly || session.isMainEvent {
        if session.isCancelled {
          sawCancellation = true
          continue
        }
        sawNonCancelledSession = true
        if let date = session.date {
          if date > now { candidates.append((date, .scheduled(round: round, session: session))) }
        } else if let day = session.scheduledDay.flatMap(publishedDay) {
          // UTC-12 is the last time zone to finish a published calendar day.
          if now < day.addingTimeInterval(36 * 3600) {
            // UTC+14 is the first possible start of that day.
            candidates.append((day.addingTimeInterval(-14 * 3600), .pending(round: round, session: session)))
          }
        } else {
          candidates.append((.distantPast, .pending(round: round, session: session)))
        }
      }
    }
    // Stable ordering for simultaneous sessions and pending days.
    if let first = candidates.enumerated().min(by: {
      $0.element.date == $1.element.date ? $0.offset < $1.offset : $0.element.date < $1.element.date
    }) {
      return first.element.answer
    }
    return sawCancellation && !sawNonCancelledSession ? .cancelled : .noUpcomingSession
  }

  static func publishedDay(_ value: String) -> Date? {
    let formatter = DateFormatter()
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.isLenient = false
    guard value.count == 10, let date = formatter.date(from: value), formatter.string(from: date) == value else { return nil }
    return date
  }

  static func publishedDayLabel(_ value: String) -> String? {
    guard publishedDay(value) != nil else { return nil }
    let parts = value.split(separator: "-")
    return "\(parts[2])/\(parts[1])/\(parts[0])"
  }
}

/// The real /next-races response. Fetching only its first round cannot answer which
/// session starts next, because the server sorts rounds by their first calendar day.
public struct UpcomingSchedulePage: Decodable {
  public struct Metadata: Decodable {
    public let page: Int
    public let per: Int
    public let total: Int

    public init(page: Int, per: Int, total: Int) {
      self.page = page
      self.per = per
      self.total = total
    }
  }
  public let items: [Race]
  public let metadata: Metadata

  public init(items: [Race], metadata: Metadata) {
    self.items = items
    self.metadata = metadata
  }
}

public enum UpcomingScheduleLoading {
  public enum LoadingError: Error { case incompleteCalendar }

  public static func rounds(fetchPage: (Int) async throws -> UpcomingSchedulePage) async throws -> [Race] {
    var rounds: [Race] = []
    var seenRoundIDs = Set<UUID>()
    var expectedPagination: (per: Int, total: Int)?
    var page = 1
    while page <= 50 {
      try Task.checkCancellation()
      let response = try await fetchPage(page)
      let metadata = response.metadata
      guard metadata.page == page, metadata.per > 0, metadata.total >= rounds.count,
        expectedPagination.map({ $0.per == metadata.per && $0.total == metadata.total }) ?? true,
        response.items.count == min(metadata.per, metadata.total - rounds.count)
        else { throw LoadingError.incompleteCalendar }
      let pageIDs = Set(response.items.map(\.id))
      guard pageIDs.count == response.items.count, seenRoundIDs.isDisjoint(with: pageIDs)
        else { throw LoadingError.incompleteCalendar }
      expectedPagination = (metadata.per, metadata.total)
      seenRoundIDs.formUnion(pageIDs)
      rounds.append(contentsOf: response.items)
      let pageCount = metadata.total / metadata.per + (metadata.total % metadata.per == 0 ? 0 : 1)
      if page >= pageCount { return rounds }
      page += 1
    }
    // Do not describe a partially fetched calendar as a complete next-session answer.
    throw LoadingError.incompleteCalendar
  }
}
