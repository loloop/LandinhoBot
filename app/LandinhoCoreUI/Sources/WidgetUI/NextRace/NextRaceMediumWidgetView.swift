//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import LandinhoFoundation
import CategoryUI
import Foundation
import SwiftUI

public struct NextRaceMediumWidgetView: View {

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
      HStack {
        VStack(alignment: .leading) {
          CategoryNameLabel(category: race.category)
            .font(.callout)
          Text(race.shortTitle)
            .font(.title3)
        }
        .frame(maxHeight: .infinity)

        VStack(alignment: .leading, spacing: 5) {
          if let message = content.emptyMessage {
            Text(message)
              .font(.caption2)
              .foregroundStyle(.secondary)
          }
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

      if let date = lastUpdatedDate {
        Text("Atualizado em: \(date.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
      }
      if content.hasPendingTimes {
        Text("Horários pendentes. Consulte a programação oficial.")
          .font(.caption2).foregroundStyle(.secondary)
      }
      if let source = race.sourceURL, let host = URL(string: source)?.host {
        Text("Fonte: \(host)").font(.caption2).foregroundStyle(.secondary)
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
