//
//  NextRaceTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import ComposableArchitecture
import Foundation
import ScheduleList
import WidgetKit

// TODO: We should remove ScheduleList from this. Completely different use cases.

struct NextRaceTimelineProvider: AppIntentTimelineProvider {

  let store = Store(initialState: ScheduleList.State(categoryTag: nil)) {
    ScheduleList()
  }

  func placeholder(in context: Context) -> NextRaceEntry {
    NextRaceEntry(date: Date())
  }

  func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> NextRaceEntry {
    NextRaceEntry(date: Date())
  }

  @MainActor
  func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<NextRaceEntry> {
    // TODO: This is good for a widget that shows the next single session as well!
    let viewStore = ViewStore(store, observe: { $0 })
    await viewStore.send(.racesRequest(.request(.get))).finish()
    guard let nextRace = viewStore.racesState.response.value else {
      return Timeline(entries: [], policy: .atEnd)
    }

    let entries: [NextRaceEntry] = [
      .init(
        date: Date(),
        response: nextRace)
    ]

    // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//    let currentDate = Date()
//    for hourOffset in 0 ..< 5 {
//      let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//      let entry = NextRaceEntry(date: entryDate)
//      entries.append(entry)
//    }

    return Timeline(entries: entries, policy: .atEnd)
  }
}
