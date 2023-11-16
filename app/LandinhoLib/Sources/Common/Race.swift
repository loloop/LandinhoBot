//
//  Race.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct Race: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, events: [RaceEvent]) {
    self.id = id
    self.title = title
    self.events = events
  }

  public let id: UUID
  public let title: String
  public let events: [RaceEvent]
}
