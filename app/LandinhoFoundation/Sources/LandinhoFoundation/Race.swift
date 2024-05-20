//
//  Race.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct Race: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, shortTitle: String, events: [RaceEvent], category: RaceCategory) {
    self.id = id
    self.title = title
    self.shortTitle = shortTitle
    self.events = events
    self.category = category
  }

  public init() {
    id = UUID()
    title = ""
    shortTitle = ""
    events = []
    category = .init(id: "", title: "", tag: "")
  }

  public let id: UUID
  public let title: String
  public let shortTitle: String
  public var events: [RaceEvent]
  public let category: RaceCategory
}

@_spi(Mock) public extension Race {
  static var mock: Race {
    .init(
      id: UUID(),
      title: "Fórmula 1 Heineken Grande Prêmio de São Paulo 2021",
      shortTitle: "São Paulo",
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
          isMainEvent: true)
      ],
      category: .init(
        id: UUID().uuidString,
        title: "Formula 1",
        tag: "f1",
        comment: "Event data by CalendarioF1.com"))
  }
}
