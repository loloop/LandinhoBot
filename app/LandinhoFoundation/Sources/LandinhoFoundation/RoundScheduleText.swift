import Foundation

/// The complete round schedule as plain text, in the same style as the Telegram bot.
public enum RoundScheduleText {
  public static func format(
    race: Race,
    locale: Locale = .current,
    timeZone: TimeZone = .current
  ) -> String {
    let formatter = DateFormatter()
    formatter.locale = locale
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = timeZone

    func dateText(_ date: Date, format: String) -> String {
      formatter.dateFormat = format
      return formatter.string(from: date)
    }

    // A pending session's scheduled day is a calendar day, not an instant to shift
    // into the device's timezone. Reject malformed days rather than invent a date.
    func scheduledDay(_ value: String?) -> String? {
      guard let value, value.count == 10 else { return nil }
      let parser = DateFormatter()
      parser.locale = Locale(identifier: "en_US_POSIX")
      parser.calendar = Calendar(identifier: .gregorian)
      parser.timeZone = TimeZone(secondsFromGMT: 0)
      parser.dateFormat = "yyyy-MM-dd"
      parser.isLenient = false
      guard let date = parser.date(from: value), parser.string(from: date) == value else { return nil }
      return value
    }

    func dayLabel(_ event: RaceEvent) -> String {
      if let date = event.date { return dateText(date, format: "dd/MM/yyyy") }
      guard let day = scheduledDay(event.scheduledDay) else { return "Data pendente" }
      let parts = day.split(separator: "-")
      return "\(parts[2])/\(parts[1])/\(parts[0])"
    }

    let sessions = race.events.enumerated().sorted { left, right in
      func key(_ event: RaceEvent) -> String {
        if let date = event.date { return dateText(date, format: "yyyy-MM-dd") }
        return scheduledDay(event.scheduledDay) ?? "9999"
      }
      let leftKey = key(left.element)
      let rightKey = key(right.element)
      if leftKey != rightKey { return leftKey < rightKey }
      switch (left.element.date, right.element.date) {
      case let (leftDate?, rightDate?) where leftDate != rightDate: return leftDate < rightDate
      case (_?, nil): return true
      case (nil, _?): return false
      default: return left.offset < right.offset
      }
    }.map { _, event in
      let day = dayLabel(event)
      if race.isCancelled || event.isCancelled {
        return "\(day) – Cancelado – \(event.title)"
      }
      guard let date = event.date else {
        return "\(day) – Horário pendente – \(event.title)"
      }
      return "\(day) às \(dateText(date, format: "HH:mm")) – \(event.title)"
    }

    let divider = "🏎️🏎️🏎️🏎️🏎️🏎️🏎️"
    var sections = ["\(race.category.title)\n\(race.title)"]
    if race.isCancelled && !sessions.isEmpty { sections.append("Etapa cancelada") }
    let schedule = sessions.isEmpty
      ? (race.isCancelled ? "Etapa cancelada" : "Horários pendentes")
      : sessions.joined(separator: "\n")
    sections.append("\(divider)\n\n\(schedule)\n\n\(divider)")
    sections.append("Horários no fuso do dispositivo: \(timeZone.identifier)")
    if let comment = race.category.comment, !comment.isEmpty { sections.append(comment) }
    if !race.isCancelled && (race.events.isEmpty || race.events.contains { $0.date == nil && !$0.isCancelled }) {
      sections.append("Ainda não conseguimos obter todos os horários. Consulte a programação oficial.")
    }
    if let source = race.sourceURL, !source.isEmpty { sections.append("Programação oficial: \(source)") }
    return sections.joined(separator: "\n\n")
  }
}
