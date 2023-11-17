//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Foundation

public struct RaceBundle: Codable, Equatable {
  public init(category: RaceCategory, nextRace: Race) {
    self.category = category
    self.nextRace = nextRace
  }
  
  public let category: RaceCategory
  public let nextRace: Race
}
