import Fluent

/// Adds optional category identity colors without changing existing categories or relationships.
struct v0_4Migration: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Category.schema).field("color", .string).update()
  }

  func revert(on database: Database) async throws {
    try await database.schema(Category.schema).deleteField("color").update()
  }
}
