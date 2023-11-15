//
//  RaceCategory.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct RaceCategory: Codable, Equatable, Identifiable, Hashable {
  public init(id: String, title: String, tag: String, comment: String? = nil) {
    self.id = id
    self.title = title
    self.tag = tag
    self.comment = comment
  }
  
  public let id: String
  public let title: String
  public let tag: String
  public let comment: String?
}
