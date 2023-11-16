//
//  NextRaceExtraLargeWidget.swift
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

struct NextRaceExtraLargeWidget: Widget {

  let kind: String = "Próxima Corrida"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind,
      provider: NextRaceTimelineProvider())
    { entry in
      Group {
        if let response = entry.response {
          NextRaceExtraLargeWidgetView(
            response: response,
            lastUpdatedDate: entry.date)
        } else {
          Image(systemName: "xmark.octagon")
        }
      }
      .containerBackground(.background, for: .widget)
    }
    .supportedFamilies([.systemExtraLarge])
    .configurationDisplayName("TODO Name")
    .description("TODO Description")
    .contentMarginsDisabled()
  }
}

struct NextRaceExtraLargeWidgetView: View {

  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("Próximas corridas")
        .font(.title)
        .bold()
      HStack(spacing: 40) {
        event()
        event()
        event()
      }
      HStack {
        Spacer()
        Text("Última atualização: \(lastUpdatedDate.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
      }
    }
  }

  @MainActor func event() -> some View {
    VStack(alignment: .leading, spacing: 10) {
      VStack(alignment: .leading) {
        Text("Formula 1")
          .font(.callout)

        Text(response.nextRace.title)
          .font(.title3)
      }

      ForEach(eventsByDate) { event in
        VStack(alignment: .leading) {
          Text(event.date)
            .font(.headline)

          ForEach(event.events) { innerEvent in
            HStack {
              Text(innerEvent.title)
                .font(.subheadline)

              Spacer()

              Text(innerEvent.date.formatted(date: .omitted, time: .shortened))
                .font(.subheadline)

            }
            .font(.caption)
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
    .multilineTextAlignment(.leading)
  }

  var eventsByDate: [EventByDate] {
    EventByDateFactory.convert(events: response.nextRace.events)
  }
}

#Preview(as: .systemExtraLarge) {
  NextRaceExtraLargeWidget()
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

