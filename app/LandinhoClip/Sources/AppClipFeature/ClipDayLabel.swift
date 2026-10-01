import Foundation
import LandinhoFoundation

/// Month names keep confirmed instants and source-only days unambiguous in any locale.
public enum ClipDayLabel {
  public static func label(for session: RaceEvent, locale: Locale = .current,
    timeZone: TimeZone = .current) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.setLocalizedDateFormatFromTemplate("dMMM")
    if let date = session.date {
      formatter.timeZone = timeZone
      return formatter.string(from: date)
    }
    guard let day = session.scheduledDay else { return "Data pendente" }
    let parts = day.split(separator: "-", omittingEmptySubsequences: false)
    guard parts.count == 3, parts[0].count == 4, parts[1].count == 2, parts[2].count == 2,
      parts.allSatisfy({ $0.allSatisfy({ "0"..."9" ~= $0 }) }),
      let year = Int(parts[0]), year > 0, let month = Int(parts[1]), let day = Int(parts[2])
    else { return "Data pendente" }
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let components = DateComponents(year: year, month: month, day: day)
    guard let date = calendar.date(from: components),
      calendar.dateComponents([.year, .month, .day], from: date) == components
    else { return "Data pendente" }
    // A source day is a calendar date, not a midnight instant in the user's zone.
    formatter.timeZone = calendar.timeZone
    return formatter.string(from: date)
  }
}
