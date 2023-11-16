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
import ScheduleList
import Common

#warning("TODO name, description, backend fixes, etc")
#warning("TODO figure out a good way to add placeholders/errors to widgets")
#warning("TODO extract views to a module so we can visualize them in the full app")
#warning("TODO extract all these widgets to a single one and switch them based on family")

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
      NextRaceMediumWidgetView(
        response: response,
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

