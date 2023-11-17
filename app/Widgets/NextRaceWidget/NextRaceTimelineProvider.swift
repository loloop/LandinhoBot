//
//  NextRaceTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import ComposableArchitecture
import Foundation
import Widgets
import WidgetKit

struct NextRaceTimelineProvider: AppIntentTimelineProvider {

  enum TimelineError: LocalizedError {
    case failure
  }

  let store = Store(initialState: Widgets.State(shouldFilterNonMainEvents: false, categoryTag: nil)) {
    Widgets()
  }

  func placeholder(in context: Context) -> NextRaceEntry {
    .placeholder
  }

  func snapshot(
    for configuration: NextRaceConfigurationIntent,
    in context: Context)
  async -> NextRaceEntry
  {
    .placeholder
  }

  @MainActor
  func timeline(for configuration: NextRaceConfigurationIntent, in context: Context) async -> Timeline<NextRaceEntry> {
    let viewStore = ViewStore(store, observe: { $0 })
    await viewStore.send(.racesRequest(.request(.get))).finish()

    guard let nextRace = viewStore.racesState.response.value else {
      return Timeline(
        entries: [
          .init(
            date: Date(),
            response: .init(),
            error: TimelineError.failure)
        ],
        policy: .atEnd)
    }

    let entries: [NextRaceEntry] = [
      .init(
        date: Date(),
        response: nextRace)
    ]

    // TODO: Fetch more than just the single next race to create a timeline
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
