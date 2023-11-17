//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Common
import Foundation
import SwiftUI

public struct NextRaceMediumWidgetView: View {

  public init(bundle: RaceBundle, lastUpdatedDate: Date) {
    self.bundle = bundle
    self.lastUpdatedDate = lastUpdatedDate
  }

  let bundle: RaceBundle
  let lastUpdatedDate: Date

  public var body: some View {
    VStack {
      HStack {
        VStack(alignment: .leading) {
          Text(bundle.category.title)
            .font(.callout)
          Text(bundle.nextRace.shortTitle)
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
    EventByDateFactory.convert(events: bundle.nextRace.events)
  }
}


