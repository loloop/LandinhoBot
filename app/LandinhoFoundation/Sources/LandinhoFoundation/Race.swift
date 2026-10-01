//
//  Race.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct Race: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, shortTitle: String, events: [RaceEvent], category: RaceCategory, sourceURL: String? = nil, isCancelled: Bool = false) {
    self.id = id
    self.title = title
    self.shortTitle = shortTitle
    self.events = events
    self.category = category
    self.sourceURL = sourceURL
    self.isCancelled = isCancelled
  }

  public init() {
    id = UUID()
    title = ""
    shortTitle = ""
    events = []
    category = .init(id: "", title: "", tag: "")
    sourceURL = nil
    isCancelled = false
  }

  public let id: UUID
  public let title: String
  public let shortTitle: String
  public var events: [RaceEvent]
  public let category: RaceCategory
  public let sourceURL: String?
  public let isCancelled: Bool

  enum CodingKeys: String, CodingKey { case id, title, shortTitle, events, category, sourceURL, isCancelled }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(UUID.self, forKey: .id)
    title = try values.decode(String.self, forKey: .title)
    shortTitle = try values.decode(String.self, forKey: .shortTitle)
    events = try values.decode([RaceEvent].self, forKey: .events)
    category = try values.decode(RaceCategory.self, forKey: .category)
    sourceURL = try values.decodeIfPresent(String.self, forKey: .sourceURL)
    isCancelled = try values.decodeIfPresent(Bool.self, forKey: .isCancelled) ?? false
  }
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
