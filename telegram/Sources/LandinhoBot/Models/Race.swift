//
//  Race.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Foundation

struct Category: Codable, Equatable {
  let title: String
  let tag: String
  let comment: String
  let races: [Race]?
}

struct Race: Codable, Equatable {
  let id: UUID
  let title: String
  let earliestEventDate: Date
  let events: [RaceEvent]
}

struct RaceEvent: Codable, Equatable, Identifiable {
  let id: UUID
  let title: String
  let date: Date
}
