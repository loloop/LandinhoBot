//
//  NextRaceLargeWidget.swift
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

#warning("TODO categoryTitle")

struct NextRaceLargeWidgetView: View {

  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text("categoryTitle")
          .font(.callout)
         Text(response.nextRace.title)
          .font(.title3)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      VStack(alignment: .leading, spacing: 5) {
        ForEach(eventsByDate) { event in
          VStack(alignment: .leading) {
            Text(event.date)
              .font(.headline)

            ForEach(event.events) { innerEvent in
              HStack {
                Text(innerEvent.title)
                  .font(.title3)

                Spacer()

                Text(innerEvent.time)
                  .font(.title3)

              }
              .font(.caption)
            }
          }
        }
        Spacer()
      }
      .frame(maxWidth: .infinity)
      .multilineTextAlignment(.leading)


      Spacer()

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

#Preview(as: .systemLarge) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}

