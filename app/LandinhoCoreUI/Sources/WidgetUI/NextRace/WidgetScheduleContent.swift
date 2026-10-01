import Foundation
import LandinhoFoundation

/// Sharing keeps the complete calendar; timeline entries provide a reference date.
struct WidgetScheduleContent {
  let race: Race
  let referenceDate: Date?
  var showNonMainEventSessions = true

  var events: [RaceEvent] {
    guard let referenceDate else { return race.events }
    return schedule(at: referenceDate).sessions
  }

  var emptyMessage: String? {
    guard let referenceDate else {
      return race.events.isEmpty ? "Horários pendentes. Consulte a programação oficial." : nil
    }
    switch schedule(at: referenceDate).emptyState {
    case .cancelledRound: return "Etapa cancelada."
    case .cancelledSessions: return "Sessões canceladas."
    case .pendingTimes: return "Horários pendentes. Consulte a programação oficial."
    case .noMainSessions: return "Nenhuma sessão principal programada."
    case .noUpcomingSessions: return "Nenhuma próxima sessão."
    case nil: return nil
    }
  }

  var hasPendingTimes: Bool {
    events.contains { $0.date == nil && !$0.isCancelled }
  }

  private func schedule(at date: Date) -> WidgetSessionSchedule {
    WidgetSessionSchedule(
      race: race,
      date: date,
      showNonMainEventSessions: showNonMainEventSessions)
  }
}
