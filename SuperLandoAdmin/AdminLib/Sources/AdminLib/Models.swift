//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 29/09/23.
//

import Foundation

public struct Category: Codable, Equatable, Identifiable, Hashable {
  public let id: String
  let title: String
  let tag: String
  let comment: String?
}

public struct Race: Codable, Equatable, Identifiable, Hashable {
  public let id: UUID
  public let title: String
  public let events: [RaceEvent]
}

public struct RaceEvent: Codable, Equatable, Identifiable, Hashable {
  public let id: UUID
  public let title: String
  public let date: Date
}


