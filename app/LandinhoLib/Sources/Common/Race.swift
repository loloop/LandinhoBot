//
//  Race.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct Race: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, shortTitle: String, events: [RaceEvent]) {
    self.id = id
    self.title = title
    self.shortTitle = shortTitle
    self.events = events
  }

  public let id: UUID
  public let title: String
  public let shortTitle: String
  public let events: [RaceEvent]
}

// TODO: Consolidate this into Race instead
public struct MegaRace: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, shortTitle: String, events: [RaceEvent], category: RaceCategory) {
    self.id = id
    self.title = title
    self.shortTitle = shortTitle
    self.events = events
    self.category = category
  }

  public let id: UUID
  public let title: String
  public let shortTitle: String
  public let events: [RaceEvent]
  public let category: RaceCategory

  public var bundled: RaceBundle {
    .init(
      category: category,
      nextRace: .init(
        id: id,
        title: title,
        shortTitle: shortTitle,
        events: events))
  }
}
