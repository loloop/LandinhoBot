//
//  NextRaceWidget.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import ComposableArchitecture
import Foundation
import SwiftUI
import WidgetKit
import ScheduleList
import Common

struct NextRaceSmallWidgetView: View {
  @ObservedObject var positionManager = WidgetPositionManager.live

  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    VStack(alignment: .leading) {
      Text(response.category.title)
        .font(.callout)
      Text(response.nextRace.shortTitle)
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
          Button(intent: NextEventIntent(race: response.nextRace)) {
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
    guard response.nextRace.events.indices.contains(positionManager.currentPosition) else {
      return nil
    }

    return response.nextRace.events[positionManager.currentPosition]
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

#Preview(as: .systemSmall) {
  NextRaceWidget()
} timeline: {
  NextRaceEntry(date: Date())
  NextRaceEntry.empty
  NextRaceEntry.placeholder
}


