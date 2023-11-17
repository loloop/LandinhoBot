//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct RaceEvent: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, date: Date, isMainEvent: Bool) {
    self.id = id
    self.title = title
    self.date = date
    self.isMainEvent = isMainEvent
  }
  
  public let id: UUID
  public let title: String
  public let date: Date
  public let isMainEvent: Bool
}
