//
//  NextRaceEntry.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Foundation
import WidgetKit
import ScheduleList

struct NextRaceEntry: TimelineEntry {
  var date: Date
  var response: ScheduleList.ScheduleListResponse?
}

extension NextRaceEntry {
  // TODO: Change this for the official times of the 2021 Interlagos Grand Prix
  static var placeholder: NextRaceEntry {
    NextRaceEntry(
      date: Date(),
      response: .init(
        categoryComment: "",
        nextRace: .init(
          id: UUID(),
          title: "FORMULA 1 HEINEKEN SILVER LAS VEGAS GRAND PRIX 2023",
          events: [
            .init(
              id: UUID(),
              title: "Treino Livre 1",
              date: Date()),
            .init(
              id: UUID(),
              title: "Treino Livre 2",
              date: Date()),
            .init(
              id: UUID(),
              title: "Treino Livre 3",
              date: Date().advanced(by: 100000)),
            .init(
              id: UUID(),
              title: "Classificação",
              date: Date().advanced(by: 100000)),
            .init(
              id: UUID(),
              title: "Corrida",
              date: Date().advanced(by: 200000))
          ])))
  }

  static var empty: NextRaceEntry {
    NextRaceEntry(
      date: Date(),
      response: .init(
        categoryComment: "Event data by CalendarioF1.com",
        nextRace: .init(
          id: UUID(),
          title: "FORMULA 1 HEINEKEN SILVER LAS VEGAS GRAND PRIX 2023",
          events: [
          ]))
    )
  }
}
