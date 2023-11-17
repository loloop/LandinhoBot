//
//  v0_2Migration.swift
//  
//
//  Created by Mauricio Cardozo on 16/11/23.
//

import Foundation
import Fluent
import Foundation
import Vapor

struct v0_2Migration: AsyncMigration {

  func prepare(on database: Database) async throws {
    try await database.schema(Race.schema)
      .field("short_title", .string, .required, .sql(.default("")))
      .update()

    try await database.schema(RaceEvent.schema)
      .field("is_main_event", .bool, .required, .sql(.default(false)))
      .update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Race.schema)
      .deleteField("short_title")
      .update()

    try await database.schema(RaceEvent.schema)
      .deleteField("is_main_event")
      .update()
  }
}
