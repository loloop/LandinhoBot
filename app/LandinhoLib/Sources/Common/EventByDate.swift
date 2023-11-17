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
      time = raceEvent.date.formatted(
        .dateTime
          .hour(.twoDigits(amPM: .abbreviated))
          .minute(.twoDigits)
      )
    }

    public let title: String
    public let time: String
    public var id: String { title }
  }
}

public struct EventByDateFactory {
  public static func convert(events: [RaceEvent]) -> [EventByDate] {
    guard !events.isEmpty else { return [] }

    return Dictionary(grouping: events) {
      $0.date.formatted(.dateTime.day().month(.twoDigits)) // This sounds inefficient
    }.map {
      EventByDate(date: $0.key, events: $0.value.map(EventByDate.Event.init))
    }.sorted {
      $0.date < $1.date
    }
  }
}
