//
//  NextRaceEntry.swift
//  WidgetsExtension
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Common
import Foundation
import WidgetKit
import Widgets

struct NextRaceEntry: TimelineEntry {
  var date: Date
  var response: Race
  var error: Error?
}

extension NextRaceEntry {
  static var placeholder: NextRaceEntry {
    NextRaceEntry(
      date: Date(),
      response: .init(
          id: UUID(),
          title: "Fórmula 1 Heineken Grande Prêmio de São Paulo 2021", shortTitle: "São Paulo",
          events: [
            .init(
              id: UUID(),
              title: "Treino Livre 1",
              date: Date(),
              isMainEvent: false),
            .init(
              id: UUID(),
              title: "Treino Livre 2",
              date: Date(), 
              isMainEvent: false),
            .init(
              id: UUID(),
              title: "Treino Livre 3",
              date: Date().advanced(by: 100000), 
              isMainEvent: false),
            .init(
              id: UUID(),
              title: "Classificação",
              date: Date().advanced(by: 100000), 
              isMainEvent: false),
            .init(
              id: UUID(),
              title: "Corrida",
              date: Date().advanced(by: 200000), 
              isMainEvent: false)
          ], 
          category:  .init(
            id: "",
            title: "Formula 1",
            tag: "f1",
            comment: "Event data by CalendarioF1.com")))
  }

  static var empty: NextRaceEntry {
    NextRaceEntry(
      date: Date(),
      response: .init(
        id: UUID(),
        title: "FORMULA 1 HEINEKEN SILVER LAS VEGAS GRAND PRIX 2023", shortTitle: "Circuit of the Americas",
        events: [],
        category: .init(
          id: "",
          title: "Formula 1",
          tag: "f1",
          comment: "Event data by CalendarioF1.com")
        )
    )
  }
}
