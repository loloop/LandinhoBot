//
//  NextRaceTimelineProvider.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import ComposableArchitecture
import Foundation
import LandinhoFoundation
import Widgets
import WidgetKit

struct NextRaceTimelineProvider: AppIntentTimelineProvider {

  enum TimelineError: LocalizedError {
    case failure
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
    // Each request owns its response, including overlapping widget configurations.
    let store = Store(initialState: Widgets.State(categoryTag: nil)) {
      Widgets()
    }
    let viewStore = ViewStore(store, observe: { $0 })
    await viewStore.send(.racesRequest(.request(.get))).finish()
    let updatedAt = Date()
    let refreshDate = updatedAt.addingTimeInterval(15 * 60)

    guard let nextRace = viewStore.racesState.response.value else {
      return Timeline(
        entries: [
          .init(
            date: updatedAt,
            response: .init(),
            error: TimelineError.failure)
        ],
        policy: .after(refreshDate))
    }

    let schedule = WidgetSessionSchedule(
      race: nextRace,
      date: updatedAt,
      showNonMainEventSessions: configuration.showNonMainEventSessions)
    let entries = schedule.transitionDates.map { date in
      NextRaceEntry(
        date: date,
        response: nextRace,
        lastUpdatedDate: updatedAt,
        showNonMainEventSessions: configuration.showNonMainEventSessions)
    }

    // Future entries remain usable even if WidgetKit defers the network refresh.
    return Timeline(entries: entries, policy: .after(refreshDate))
  }
}
