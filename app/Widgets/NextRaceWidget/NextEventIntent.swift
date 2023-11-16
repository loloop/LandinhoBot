//
//  NextEventIntent.swift
//  VroomVroom
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Common
import Foundation
import AppIntents

struct NextEventIntent: AppIntent {
  init(race: Race) {
    eventCount = race.events.count
  }

  init() {
    eventCount = 0
  }

  let eventCount: Int

  func perform() async throws -> some IntentResult {
    WidgetPositionManager.nextButtonTapped(maxEvents: eventCount)
    return .result()
  }

  static var title: LocalizedStringResource = "Next Event"
  static var description: IntentDescription? = "Mostra o próximo evento de uma corrida"
}

class WidgetPositionManager: ObservableObject {
  static let live = WidgetPositionManager()

  @Published var currentPosition = 0

  static func nextButtonTapped(maxEvents: Int) {
    // TODO: take in the race and compare to the current one to reset
    // TODO: reset if its the end of the array
    if Self.live.currentPosition == maxEvents - 1 {
      Self.live.currentPosition = 0
    } else {
      Self.live.currentPosition += 1
    }
  }
}
