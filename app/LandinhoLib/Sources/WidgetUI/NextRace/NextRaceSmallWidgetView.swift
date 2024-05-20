//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import LandinhoFoundation
import Foundation
import SwiftUI
import WidgetKit

public struct NextRaceSmallWidgetView: View {

  public init(race: Race, lastUpdatedDate: Date) {
    self.race = race
    self.lastUpdatedDate = lastUpdatedDate
  }

  @State var positionManager = WidgetPositionManager.live
  let race: Race
  let lastUpdatedDate: Date

  public var body: some View {
    Self._printChanges()

    return VStack(alignment: .leading) {
      Text(race.category.title)
        .font(.callout)
      Text(race.shortTitle)
        .font(.title3)
      Spacer()

      VStack(alignment: .leading) {
        Text(currentEventDate)
          .frame(maxWidth: .infinity, alignment: .trailing)
        HStack {
          Text(currentEventTitle)
            .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        HStack {
          Button(intent: NextEventIntent(race: race)) {
            Image(systemName: "chevron.right")
          }
          Spacer()
          Text(currentEventTime)
            .font(.title2)
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

  // TODO: Bring this to `EventByDate` to standardize date formatting
  var currentEvent: RaceEvent? {
    guard race.events.indices.contains(positionManager.currentPosition) else {
      return nil
    }

    return race.events[positionManager.currentPosition]
  }

  var currentEventDate: String {
    guard let event = currentEvent else {
      return ""
    }

    return event.date.formatted(
      .dateTime
        .day(.twoDigits)
        .month(.twoDigits)
    )
  }

  var currentEventTitle: String {
    currentEvent?.title ?? ""
  }

  var currentEventTime: String {
    guard let event = currentEvent else {
      return ""
    }

    return event.date.formatted(
      .dateTime
      .hour(.twoDigits(amPM: .abbreviated))
      .minute(.twoDigits)
    )
  }
}
