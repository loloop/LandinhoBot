//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Fluent
import Foundation
import Vapor

struct v0_1Migration: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Category.schema)
      .id()
      .field("title", .string, .required)
      .field("tag", .string, .required)
      .field("comment", .string)
      .unique(on: "title")
      .unique(on: "tag")
      .create()

    try await database.schema(Race.schema)
      .id()
      .field("title", .string, .required)
      .field("category", .uuid, Category.reference)
      .field("earliest_event_date", .datetime, .required)
      .create()

    try await database.schema(RaceEvent.schema)
      .id()
      .field("title", .string, .required)
      .field("date", .datetime, .required)
      .field("race", .uuid, Race.reference)
      .create()
    
    try await database.schema(Chat.schema)
      .id()
      .field("chat_id", .string, .required)
      .field("subbed_to", .array(of: .string), .required)
      .create()
  }

  func revert(on database: Database) async throws {
    try await database.schema(RaceEvent.schema)
      .delete()

    try await database.schema(Race.schema)
      .delete()

    try await database.schema(Category.schema)
      .delete()

    try await database.schema(Chat.schema)
      .delete()
  }
}
