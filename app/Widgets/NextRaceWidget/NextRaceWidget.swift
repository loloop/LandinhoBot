//
//  NextRaceWidget.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Common
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
              bundle: entry.response,
              lastUpdatedDate: entry.date)
          } else {
            NextRaceWidgetView(
              bundle: .init(),
              lastUpdatedDate: entry.date)
            .redacted(reason: .placeholder)
          }
        }
        .containerBackground(.background, for: .widget)
      }
      .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
      .configurationDisplayName("Próxima corrida")
      .description("Mostra a próxima corrida que vai acontecer")
  }
}

struct NextRaceWidgetView: View {

  @Environment(\.widgetFamily) var family
  let bundle: RaceBundle
  let lastUpdatedDate: Date

  var body: some View {
    switch family {
    case .systemSmall:
      NextRaceSmallWidgetView(
        bundle: bundle,
        lastUpdatedDate: lastUpdatedDate)
    case .systemMedium:
      NextRaceMediumWidgetView(
        bundle: bundle,
        lastUpdatedDate: lastUpdatedDate)
    case .systemLarge:
      NextRaceLargeWidgetView(
        bundle: bundle,
        lastUpdatedDate: lastUpdatedDate)
    case .systemExtraLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline:
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
