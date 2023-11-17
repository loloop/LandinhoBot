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

struct NextRaceMediumWidgetView: View {

  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    VStack {
      HStack {
        VStack(alignment: .leading) {
          Text(response.category.title)
            .font(.callout)
          Text(response.nextRace.shortTitle)
            .font(.title3)
        }
        .frame(maxHeight: .infinity)

        VStack(alignment: .leading, spacing: 5) {
          ForEach(eventsByDate) { event in
            VStack(alignment: .leading) {
              Text(event.date)
                .font(.system(size: 10))

              ForEach(event.events) { innerEvent in
                HStack {
                  Text(innerEvent.title)
                  Spacer()
                  Text(innerEvent.time)
                }
                .font(.caption)
              }
            }
          }
        }
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
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}



