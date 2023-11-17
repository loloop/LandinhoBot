//
//  NextRaceWidget.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import WidgetKit
import WidgetUI
import ScheduleList
import Common

// TODO: extract views to a module so we can visualize them in the full app

struct NextRaceWidget: Widget {
  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: "NextRaceWidget",
      provider: NextRaceTimelineProvider()) { entry in
        Group {
          if let response = entry.response {
            NextRaceWidgetView(
              response: response,
              lastUpdatedDate: entry.date)
          } else {
            NextRaceWidgetView(
              response: .init(),
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
  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    switch family {
    case .systemSmall:
      NextRaceSmallWidgetView(
        response: response,
        lastUpdatedDate: lastUpdatedDate)
    case .systemMedium:
      #warning("TODO remove RaceBundle initializer")
      NextRaceMediumWidgetView(
        response: .init(
          category: response.category,
          nextRace: response.nextRace),
        lastUpdatedDate: lastUpdatedDate)
    case .systemLarge:
      NextRaceLargeWidgetView(
        response: response,
        lastUpdatedDate: lastUpdatedDate)
    case .systemExtraLarge:
      // Disabled for now -- maybe this isn't what
      // TODO: Enable when Timeline provider fetches more than a single race
      NextRaceExtraLargeWidgetView(
        response: response,
        lastUpdatedDate: lastUpdatedDate)
    case .accessoryCircular, .accessoryRectangular, .accessoryInline:
      // TODO: Accessory Widgets
      EmptyView()
    @unknown default:
      EmptyView()
    }
  }
}

import Foundation
import WidgetKit
import WidgetUI

#Preview(as: .systemMedium) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}
