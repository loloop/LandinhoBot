//
//  EventByDate.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Foundation

public struct EventByDate: Identifiable {
  public let date: String
  public let events: [Event]
  public var id: String { date }

  public struct Event: Identifiable {
    init(raceEvent: RaceEvent) {
      title = raceEvent.title
      time = raceEvent.timeLabel
      id = raceEvent.id
    }

    public let title: String
    public let time: String
    public let id: UUID
  }
}

public struct EventByDateFactory {
  public static func convert(events: [RaceEvent]) -> [EventByDate] {
    guard !events.isEmpty else { return [] }

    let sorted = events.sorted {
      let lhs = $0.date.map { ISO8601DateFormatter().string(from: $0) } ?? $0.scheduledDay ?? "9999"
      let rhs = $1.date.map { ISO8601DateFormatter().string(from: $0) } ?? $1.scheduledDay ?? "9999"
      return lhs < rhs
    }
    var days: [String] = []
    for event in sorted where !days.contains(event.dayLabel) { days.append(event.dayLabel) }
    return days.map { day in EventByDate(date: day, events: sorted.filter { $0.dayLabel == day }.map(EventByDate.Event.init)) }
  }
}
