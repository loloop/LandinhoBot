//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Common
import Foundation
import SwiftUI
import WidgetKit

public struct NextRaceSmallWidgetView: View {

  public init(bundle: RaceBundle, lastUpdatedDate: Date) {
    self.bundle = bundle
    self.lastUpdatedDate = lastUpdatedDate
  }

  @ObservedObject var positionManager = WidgetPositionManager.live
  let bundle: RaceBundle
  let lastUpdatedDate: Date

  public var body: some View {
    VStack(alignment: .leading) {
      Text(bundle.category.title)
        .font(.callout)
      Text(bundle.nextRace.shortTitle)
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
          Button(intent: NextEventIntent(race: bundle.nextRace)) {
            Image(systemName: "chevron.right")
          }
          Spacer()
          Text(currentEventTime)
            .font(.title2)
        }

        Text("Última atualização: \(lastUpdatedDate.formatted(date: .omitted, time: .shortened))")
          .font(.system(size: 10))
          .foregroundStyle(.secondary)
          .frame(maxWidth: .infinity)
      }
      .font(.caption)
    }
  }

  // TODO: Bring this to `EventByDate` to standardize date formatting
  var currentEvent: RaceEvent? {
    guard bundle.nextRace.events.indices.contains(positionManager.currentPosition) else {
      return nil
    }

    return bundle.nextRace.events[positionManager.currentPosition]
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
