//
//  RaceCategory.swift
//
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct RaceCategory: Codable, Equatable, Identifiable, Hashable {
  public init(id: String, title: String, tag: String, comment: String? = nil, color: CategoryColor? = nil) {
    self.id = id
    self.title = title
    self.tag = tag
    self.comment = comment
    self.color = color
  }
  
  public let id: String
  public let title: String
  public let tag: String
  public let comment: String?
  public let color: CategoryColor?

  public var resolvedColor: CategoryColor { color ?? .fallback(for: tag) }

  private enum CodingKeys: String, CodingKey {
    case id, title, tag, comment, color
  }

  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    tag = try container.decode(String.self, forKey: .tag)
    comment = try container.decodeIfPresent(String.self, forKey: .comment)
    // A missing or invalid optional color never makes an otherwise valid calendar unavailable.
    color = try? container.decodeIfPresent(CategoryColor.self, forKey: .color)
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(title, forKey: .title)
    try container.encode(tag, forKey: .tag)
    try container.encodeIfPresent(comment, forKey: .comment)
    // Explicit null lets the category editor restore the automatic color on PATCH.
    try container.encode(color, forKey: .color)
  }
}
