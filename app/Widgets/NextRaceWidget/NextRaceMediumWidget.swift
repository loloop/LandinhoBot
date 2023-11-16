//
//  NextRaceMediumWidget.swift
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

#warning("TODO categoryTitle, shortTitle")

struct NextRaceMediumWidget: Widget {

  let kind: String = "Próxima Corrida"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      provider: NextRaceTimelineProvider())
    { entry in
      Group {
        if let response = entry.response {
          NextRaceMediumWidgetView(
            response: response,
            lastUpdatedDate: entry.date)
        } else {
          Image(systemName: "xmark.octagon")
        }
      }
      .containerBackground(.background, for: .widget)
    }
    .supportedFamilies([.systemMedium])
    .configurationDisplayName("TODO Name")
    .description("TODO Description")
  }
}

struct NextRaceMediumWidgetView: View {

  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    VStack {
      HStack {
        VStack(alignment: .leading) {
          Text("categoryTitle")
            .font(.callout)
          Text(response.nextRace.title)
            .font(.title3)
        }

        Spacer()

        VStack(alignment: .leading, spacing: 5) {
          ForEach(eventsByDate) { event in
            VStack(alignment: .leading) {
              Text(event.date)
                .font(.subheadline)

              ForEach(event.events) { innerEvent in
                HStack {
                  Text(innerEvent.title)
                  Spacer()
                  Text(innerEvent.date.formatted(date: .omitted, time: .shortened))
                }
                .font(.caption)
              }
            }
          }
          Spacer()
        }

        Spacer()
      }

      Text("Última atualização: \(lastUpdatedDate.formatted(date: .omitted, time: .shortened))")
        .font(.system(size: 10))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
    }

  }

  var eventsByDate: [EventByDate] {
    EventByDateFactory.convert(events: response.nextRace.events)
  }
}

#Preview(as: .systemMedium) {
  NextRaceMediumWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry(
    date: Date(),
    response: .init(
      categoryComment: "Event data by CalendarioF1.com",
      nextRace: .init(
        id: UUID(),
        title: "FORMULA 1 HEINEKEN SILVER LAS VEGAS GRAND PRIX 2023",
        events: [
        ]))
  )
  NextRaceEntry(
    date: Date(),
    response: .init(
      categoryComment: "Event data by CalendarioF1.com",
      nextRace: .init(
        id: UUID(),
        title: "FORMULA 1 HEINEKEN SILVER LAS VEGAS GRAND PRIX 2023",
        events: [
          .init(
            id: UUID(),
            title: "Treino Livre 1",
            date: Date()),
          .init(
            id: UUID(),
            title: "Treino Livre 2",
            date: Date()),
          .init(
            id: UUID(),
            title: "Treino Livre 3",
            date: Date()),
          .init(
            id: UUID(),
            title: "Classificação",
            date: Date()),
          .init(
            id: UUID(),
            title: "Corrida",
            date: Date().advanced(by: 200000))
        ]))
  )
}


