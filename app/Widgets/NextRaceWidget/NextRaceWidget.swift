//
//  NextRaceWidget.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Common
import ComposableArchitecture
import Foundation
import ScheduleList
import SwiftUI
import WidgetKit
import WidgetUI

// TODO: extract views to a module so we can visualize them in the full app

struct NextRaceWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "NextRaceWidget",
      provider: NextRaceTimelineProvider()) { entry in
        Group {
          if let response = entry.response {
            #warning("TODO remove RaceBundle initializer")
            NextRaceWidgetView(
              bundle: .init(category: response.category, nextRace: response.nextRace),
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

// MARK: Previews

#Preview(as: .systemSmall) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemSmall) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemMedium) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

#Preview(as: .systemLarge) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}
