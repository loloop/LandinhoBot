//
//  NextRaceLargeWidgetView.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import LandinhoFoundation
import CategoryUI
import Foundation
import SwiftUI

public struct NextRaceLargeWidgetView: View {

  public init(race: Race, lastUpdatedDate: Date?, referenceDate: Date? = nil, showNonMainEventSessions: Bool = true) {
    self.race = race
    self.lastUpdatedDate = lastUpdatedDate
    self.referenceDate = referenceDate
    self.showNonMainEventSessions = showNonMainEventSessions
  }

  let race: Race
  let lastUpdatedDate: Date?
  let referenceDate: Date?
  let showNonMainEventSessions: Bool

  public var body: some View {
    VStack {
      VStack(alignment: .leading) {
        CategoryNameLabel(category: race.category)
          .font(.callout)
         Text(race.title)
          .font(.title3)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      VStack(alignment: .leading, spacing: 5) {
        if let message = content.emptyMessage {
          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
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

      if let date = lastUpdatedDate {
        Text("Atualizado em: \(date.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
      }
      if content.hasPendingTimes {
        Text("Horários pendentes. Consulte a programação oficial.")
          .font(.caption2)
          .foregroundStyle(.secondary)
      }
    }
  }

  var eventsByDate: [EventByDate] {
    EventByDateFactory.convert(events: content.events)
  }

  var content: WidgetScheduleContent {
    WidgetScheduleContent(race: race, referenceDate: referenceDate, showNonMainEventSessions: showNonMainEventSessions)
  }
}
