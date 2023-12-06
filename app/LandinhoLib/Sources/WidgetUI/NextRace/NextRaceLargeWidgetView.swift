//
//  NextRaceLargeWidgetView.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Common
import Foundation
import SwiftUI

public struct NextRaceLargeWidgetView: View {

  public init(race: Race, lastUpdatedDate: Date?) {
    self.race = race
    self.lastUpdatedDate = lastUpdatedDate
  }

  let race: Race
  let lastUpdatedDate: Date?

  public var body: some View {
    VStack {
      VStack(alignment: .leading) {
        Text(race.category.title)
          .font(.callout)
         Text(race.title)
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

      if let date = lastUpdatedDate {
        Text("Atualizado em: \(date.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
      }
    }
  }

  var eventsByDate: [EventByDate] {
    EventByDateFactory.convert(events: race.events)
  }
}
