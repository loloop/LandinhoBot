//
//  NextRaceWidget.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import LandinhoFoundation
import ComposableArchitecture
import Foundation
import SwiftUI
import Widgets
import WidgetKit
import WidgetUI

struct NextRaceWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "NextRaceWidget",
      provider: NextRaceTimelineProvider()) { entry in
        Group {
          if entry.error == nil {
            NextRaceWidgetView(
              race: entry.response,
              lastUpdatedDate: entry.lastUpdatedDate,
              referenceDate: entry.date,
              showNonMainEventSessions: entry.showNonMainEventSessions)
          } else {
            NextRaceWidgetView(
              race: .init(),
              lastUpdatedDate: entry.date)
            .redacted(reason: .placeholder)
          }
        }
        .containerBackground(.background, for: .widget)
      }
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
      .configurationDisplayName("Próxima corrida")
      .description("Mostra a próxima corrida que vai acontecer")
  }
}

struct NextRaceWidgetView: View {

  @Environment(\.widgetFamily) var family
  let race: Race
  let lastUpdatedDate: Date
  var referenceDate: Date? = nil
  var showNonMainEventSessions = true

  var body: some View {
    switch family {
    case .systemSmall:
      NextRaceSmallWidgetView(
        race: race,
        lastUpdatedDate: lastUpdatedDate,
        referenceDate: referenceDate,
        showNonMainEventSessions: showNonMainEventSessions)
    case .systemMedium:
      NextRaceMediumWidgetView(
        race: race,
        lastUpdatedDate: lastUpdatedDate,
        referenceDate: referenceDate,
        showNonMainEventSessions: showNonMainEventSessions)
    case .systemLarge:
      NextRaceLargeWidgetView(
        race: race,
        lastUpdatedDate: lastUpdatedDate,
        referenceDate: referenceDate,
        showNonMainEventSessions: showNonMainEventSessions)
    case .systemExtraLarge:
      NextRaceExtraLargeWidgetView(
        race: race,
        lastUpdatedDate: lastUpdatedDate,
        referenceDate: referenceDate,
        showNonMainEventSessions: showNonMainEventSessions)
    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
      // TODO: Accessory Widgets
      EmptyView()
    @unknown default:
      EmptyView()
    }
  }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(
    date: Date(),
    response: .init(),
    error: NextRaceTimelineProvider.TimelineError.failure)
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemSmall) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(
    date: Date(),
    response: .init(),
    error: NextRaceTimelineProvider.TimelineError.failure)
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemMedium) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(
    date: Date(),
    response: .init(),
    error: NextRaceTimelineProvider.TimelineError.failure)
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemLarge) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(
    date: Date(),
    response: .init(),
    error: NextRaceTimelineProvider.TimelineError.failure)
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemExtraLarge) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}
