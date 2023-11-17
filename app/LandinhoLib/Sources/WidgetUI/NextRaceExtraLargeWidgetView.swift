//
//  NextRaceExtraLargeWidgetView.swift
//
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Common
import Foundation
import SwiftUI

// TODO: Finish this Widget once we have more a `next-races` endpoint

public struct NextRaceExtraLargeWidgetView: View {

  let response: RaceBundle
  let lastUpdatedDate: Date

  public var body: some View {
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
