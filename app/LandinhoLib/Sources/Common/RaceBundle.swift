//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Foundation

public struct RaceBundle: Codable, Equatable, Identifiable {
  public init(category: RaceCategory, nextRace: Race) {
    self.category = category
    self.nextRace = nextRace
  }

  public init() {
    // init meant for placeholder widget views
    category = RaceCategory(id: "", title: "Formula 1", tag: "")
    nextRace = Race(
      id: UUID(),
      title: "Placeholder",
      shortTitle: "Placeholder",
      events: [
        .init(id: UUID(), title: "Placeholder", date: Date(), isMainEvent: false),
        .init(id: UUID(), title: "Placeholder", date: Date(), isMainEvent: false),
        .init(id: UUID(), title: "Placeholder", date: Date().advanced(by: 100000), isMainEvent: false),
        .init(id: UUID(), title: "Placeholder", date: Date().advanced(by: 100000), isMainEvent: false),
        .init(id: UUID(), title: "Placeholder", date: Date().advanced(by: 200000), isMainEvent: true),
      ])
  }

  public let category: RaceCategory
  public var nextRace: Race
  public var id: UUID { nextRace.id }
}
