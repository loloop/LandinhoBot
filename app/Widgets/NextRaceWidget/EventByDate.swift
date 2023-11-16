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
  let events: [RaceEvent]
  var id: String { date }
}

struct EventByDateFactory {
  static func convert(events: [RaceEvent]) -> [EventByDate] {
    guard !events.isEmpty else { return [] }

    return Dictionary(grouping: events) {
      $0.date.formatted(.dateTime.day().month(.twoDigits)) // This sounds inefficient
    }.map {
      EventByDate(date: $0.key, events: $0.value)
    }.sorted {
      $0.date < $1.date
    }
  }
}
