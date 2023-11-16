//
//  EventByDate.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Common
import Foundation

struct EventByDate: Identifiable {
  let date: String
  let events: [Event]
  var id: String { date }

  struct Event: Identifiable {
    init(raceEvent: RaceEvent) {
      title = raceEvent.title
      time = raceEvent.date.formatted(
        .dateTime
          .hour(.twoDigits(amPM: .abbreviated))
          .minute(.twoDigits)
      )
    }

    let title: String
    let time: String
    var id: String { title }
  }
}

struct EventByDateFactory {
  static func convert(events: [RaceEvent]) -> [EventByDate] {
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
