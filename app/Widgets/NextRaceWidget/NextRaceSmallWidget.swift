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

#warning("TODO name, description, backend fixes, etc")
#warning("TODO figure out a good way to add placeholders/errors to widgets")
#warning("TODO extract views to a module so we can visualize them in the full app")
#warning("TODO extract all these widgets to a single one and switch them based on family")

struct NextRaceSmallWidgetView: View {
  @ObservedObject var positionManager = WidgetPositionManager.live

  let response: ScheduleList.ScheduleListResponse
  let lastUpdatedDate: Date

  var body: some View {
    VStack(alignment: .leading) {
      Text("categoryName")
        .font(.callout)
      Text("shortTitle")
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

    return event.date.formatted(date: .numeric, time: .omitted)
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


