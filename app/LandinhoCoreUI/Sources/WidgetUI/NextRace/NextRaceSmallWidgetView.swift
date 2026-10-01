//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import LandinhoFoundation
import Foundation
import SwiftUI

public struct NextRaceSmallWidgetView: View {

  public init(race: Race, lastUpdatedDate: Date, referenceDate: Date? = nil, showNonMainEventSessions: Bool = true) {
    self.race = race
    self.lastUpdatedDate = lastUpdatedDate
    self.referenceDate = referenceDate
    self.showNonMainEventSessions = showNonMainEventSessions
  }

  let race: Race
  let lastUpdatedDate: Date
  let referenceDate: Date?
  let showNonMainEventSessions: Bool

  public var body: some View {
    VStack(alignment: .leading) {
      Text(race.category.title)
        .font(.callout)
      Text(race.shortTitle)
        .font(.title3)
      Spacer()

      VStack(alignment: .leading) {
        if let event = currentEvent {
          Text(event.dayLabel)
            .frame(maxWidth: .infinity, alignment: .trailing)
          Text(event.title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .trailing)
          Text(event.timeLabel)
            .font(.title2)
            .frame(maxWidth: .infinity, alignment: .trailing)
        } else if let message = content.emptyMessage {
          Text(message)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        Text("Atualizado em: \(lastUpdatedDate.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
      }
      .font(.caption)
      .invalidatableContent()
    }
  }

  var content: WidgetScheduleContent {
    WidgetScheduleContent(race: race, referenceDate: referenceDate, showNonMainEventSessions: showNonMainEventSessions)
  }

  var currentEvent: RaceEvent? {
    content.events.first
  }
}
