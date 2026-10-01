import Foundation

/// A widget's view of the remaining session starts in one round.
/// Pending times remain visible: an unknown start is not a past or cancelled session.
public struct WidgetSessionSchedule {
  public enum EmptyState: Equatable {
    case cancelledRound
    case cancelledSessions
    case pendingTimes
    case noMainSessions
    case noUpcomingSessions
  }

  public init(race: Race, date: Date, showNonMainEventSessions: Bool = true) {
    self.race = race
    self.date = date
    self.showNonMainEventSessions = showNonMainEventSessions
  }

  let race: Race
  let date: Date
  let showNonMainEventSessions: Bool

  var configuredSessions: [RaceEvent] {
    race.events.filter { showNonMainEventSessions || $0.isMainEvent }
  }

  public var sessions: [RaceEvent] {
    guard !race.isCancelled else { return [] }
    return configuredSessions.enumerated()
      .filter { !$0.element.isCancelled && ($0.element.date.map { $0 > date } ?? true) }
      .sorted { lhs, rhs in
        switch (lhs.element.date, rhs.element.date) {
        case let (left?, right?) where left != right: return left < right
        case (_?, nil): return true
        case (nil, _?): return false
        default: return lhs.offset < rhs.offset
        }
      }
      .map(\.element)
  }

  /// Entry dates remove starts that are no longer upcoming without a network request.
  public var transitionDates: [Date] {
    guard !race.isCancelled else { return [date] }
    let starts = configuredSessions
      .filter { !$0.isCancelled }
      .compactMap(\.date)
      .filter { $0 > date }
    return [date] + Set(starts).sorted()
  }

  public var emptyState: EmptyState? {
    guard sessions.isEmpty else { return nil }
    if race.isCancelled { return .cancelledRound }
    if race.events.isEmpty { return .pendingTimes }
    if configuredSessions.isEmpty { return .noMainSessions }
    if configuredSessions.allSatisfy(\.isCancelled) { return .cancelledSessions }
    return .noUpcomingSessions
  }
}
