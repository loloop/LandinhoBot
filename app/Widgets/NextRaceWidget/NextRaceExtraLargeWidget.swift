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

              Text(innerEvent.time)
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
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

