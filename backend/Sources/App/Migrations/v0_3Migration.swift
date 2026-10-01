import Fluent
import SQLKit

struct v0_3Migration: AsyncMigration {
  func prepare(on database: Database) async throws {
    try await database.schema(Category.schema)
      .field("import_provider", .string)
      .field("import_interval_days", .int, .required, .sql(.default(7)))
      .field("imports_enabled", .bool, .required, .sql(.default(false)))
      .field("next_import_at", .datetime)
      .field("last_import_at", .datetime)
      .update()
    try await database.schema(Race.schema)
      .field("source_id", .string)
      .field("source_url", .string)
      .field("schedule_end_date", .datetime)
      .field("is_cancelled", .bool, .required, .sql(.default(false)))
      .field("import_warning", .string)
      .unique(on: "category", "source_id")
      .update()
    try await database.schema(RaceEvent.schema)
      .field("source_id", .string)
      .field("source_url", .string)
      .field("scheduled_day", .string)
      .field("is_cancelled", .bool, .required, .sql(.default(false)))
      .field("import_warning", .string)
      .unique(on: "race", "source_id")
      .update()
    guard let sql = database as? any SQLDatabase else { throw MigrationError.requiresSQL }
    try await sql.raw("ALTER TABLE race_event ALTER COLUMN date DROP NOT NULL").run()
    try await database.schema(ImportRun.schema)
      .id()
      .field("category_tag", .string, .required)
      .field("provider", .string, .required)
      .field("trigger", .string, .required)
      .field("started_at", .datetime, .required)
      .field("finished_at", .datetime)
      .field("status", .string, .required)
      .field("changes", .array(of: .json), .required)
      .field("issues", .array(of: .json), .required)
      .create()
  }

  func revert(on database: Database) async throws {
    guard let sql = database as? any SQLDatabase else { throw MigrationError.requiresSQL }
    // PostgreSQL refuses this if pending times still exist, rather than fabricating dates.
    try await sql.raw("ALTER TABLE race_event ALTER COLUMN date SET NOT NULL").run()
    try await database.schema(ImportRun.schema).delete()
    try await database.schema(RaceEvent.schema)
      .deleteUnique(on: "race", "source_id")
      .deleteField("source_id").deleteField("source_url").deleteField("scheduled_day")
      .deleteField("is_cancelled").deleteField("import_warning").update()
    try await database.schema(Race.schema)
      .deleteUnique(on: "category", "source_id")
      .deleteField("source_id").deleteField("source_url").deleteField("schedule_end_date")
      .deleteField("is_cancelled").deleteField("import_warning").update()
    try await database.schema(Category.schema)
      .deleteField("import_provider").deleteField("import_interval_days").deleteField("imports_enabled")
      .deleteField("next_import_at").deleteField("last_import_at").update()
  }

  enum MigrationError: Error { case requiresSQL }
}
