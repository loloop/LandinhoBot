import Foundation
import LandinhoFoundation
import SQLiteData

// Codable payloads preserve pending times, cancellations, source links and category colors
// without coupling the API models to SQLite. Page membership is separate from each round's
// latest payload, so a detail refresh also updates subsequently restored schedule pages.
@Table("calendarSnapshots")
private struct CalendarSnapshotRow {
  let id: String
  let scope: String
  let payload: Data
  let updatedAt: Double
}

@Table("calendarRounds")
private struct CalendarRoundRow {
  let id: String
  let payload: Data
  let updatedAt: Double
}

private struct PageMembership: Codable {
  let roundIDs: [UUID]
  let page: Int
  let per: Int
  let total: Int
}

actor CalendarDatabase {
  private let url: URL?
  private let source: String
  private var database: DatabaseQueue?

  init(url: URL?, source: String) {
    self.url = url
    self.source = Self.storageSource(source)
  }

  private static func storageSource(_ source: String) -> String {
    guard var components = URLComponents(string: source),
      let scheme = components.scheme?.lowercased(), ["http", "https"].contains(scheme) else { return source }
    // Only the API's address identifies saved data. Never persist credentials or unused
    // query/fragment values supplied in a development URL override.
    components.user = nil
    components.password = nil
    components.query = nil
    components.fragment = nil
    components.scheme = scheme
    components.host = components.host?.lowercased()
    let path = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    components.path = path.isEmpty ? "" : "/" + path
    if (scheme == "https" && components.port == 443) || (scheme == "http" && components.port == 80) {
      components.port = nil
    }
    return components.string ?? "calendar"
  }

  private func connection() throws -> DatabaseQueue {
    if let database { return database }
    let database: DatabaseQueue
    if let url {
      try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
      database = try DatabaseQueue(path: url.path)
    } else {
      database = try DatabaseQueue()
    }
    var migrator = DatabaseMigrator()
    migrator.registerMigration("Create public calendar storage") { db in
      try #sql("""
        CREATE TABLE "calendarSnapshots" (
          "id" TEXT PRIMARY KEY NOT NULL,
          "scope" TEXT NOT NULL,
          "payload" BLOB NOT NULL,
          "updatedAt" REAL NOT NULL
        ) STRICT
        """).execute(db)
      try #sql("CREATE INDEX \"calendarSnapshots_scope\" ON \"calendarSnapshots\" (\"scope\")").execute(db)
      try #sql("""
        CREATE TABLE "calendarRounds" (
          "id" TEXT PRIMARY KEY NOT NULL,
          "payload" BLOB NOT NULL,
          "updatedAt" REAL NOT NULL
        ) STRICT
        """).execute(db)
    }
    try migrator.migrate(database)
    self.database = database
    return database
  }

  func loadCategories() throws -> SavedCalendar<[RaceCategory]>? {
    let key = source + "|categories"
    return try connection().read { db in
      guard let row = try CalendarSnapshotRow.find(key).fetchOne(db) else { return nil }
      return SavedCalendar(value: try JSONDecoder().decode([RaceCategory].self, from: row.payload),
        updatedAt: Date(timeIntervalSince1970: row.updatedAt))
    }
  }

  func saveCategories(_ categories: [RaceCategory], updatedAt: Date) throws {
    let key = source + "|categories"
    let row = CalendarSnapshotRow(id: key, scope: key, payload: try JSONEncoder().encode(categories),
      updatedAt: updatedAt.timeIntervalSince1970)
    try connection().write { db in try CalendarSnapshotRow.upsert { row }.execute(db) }
  }

  func loadPage(_ query: CalendarQuery, page: Int) throws -> SavedCalendar<CalendarPage>? {
    let scope = try scope(for: query)
    return try connection().read { db in
      guard let row = try CalendarSnapshotRow.find(scope + "|\(page)").fetchOne(db) else { return nil }
      let membership = try JSONDecoder().decode(PageMembership.self, from: row.payload)
      var items: [Race] = []
      for id in membership.roundIDs {
        // A removed round makes this page incomplete: fetch it again rather than restore a
        // partial page with incorrect pagination metadata.
        guard let round = try CalendarRoundRow.find(roundKey(id)).fetchOne(db) else { return nil }
        items.append(try JSONDecoder().decode(Race.self, from: round.payload))
      }
      return SavedCalendar(value: CalendarPage(items: items, page: membership.page, per: membership.per,
        total: membership.total), updatedAt: Date(timeIntervalSince1970: row.updatedAt))
    }
  }

  func savePage(_ page: CalendarPage, query: CalendarQuery, updatedAt: Date) throws {
    guard page.page > 0, page.per == query.per, page.total >= 0 else {
      throw CocoaError(.coderInvalidValue)
    }
    let scope = try scope(for: query)
    let membership = PageMembership(roundIDs: page.items.map(\.id), page: page.page, per: page.per, total: page.total)
    let row = CalendarSnapshotRow(id: scope + "|\(page.page)", scope: scope,
      payload: try JSONEncoder().encode(membership), updatedAt: updatedAt.timeIntervalSince1970)
    let rounds = try page.items.map { try roundRow($0, updatedAt: updatedAt) }
    try connection().write { db in
      if let first = try CalendarSnapshotRow.find(scope + "|1").fetchOne(db), first.updatedAt > row.updatedAt {
        return
      }
      // Refreshing the first page invalidates older pages of this exact ordering.
      if page.page == 1 { try CalendarSnapshotRow.where { $0.scope.eq(scope) }.delete().execute(db) }
      for round in rounds { try save(round, in: db) }
      try CalendarSnapshotRow.upsert { row }.execute(db)
    }
  }

  func loadRound(_ id: UUID) throws -> SavedCalendar<Race>? {
    try connection().read { db in
      guard let row = try CalendarRoundRow.find(roundKey(id)).fetchOne(db) else { return nil }
      return SavedCalendar(value: try JSONDecoder().decode(Race.self, from: row.payload),
        updatedAt: Date(timeIntervalSince1970: row.updatedAt))
    }
  }

  func saveRound(_ race: Race, updatedAt: Date) throws {
    let row = try roundRow(race, updatedAt: updatedAt)
    try connection().write { db in try save(row, in: db) }
  }

  func removeRound(_ id: UUID) throws {
    try connection().write { db in try CalendarRoundRow.find(roundKey(id)).delete().execute(db) }
  }

  private func roundKey(_ id: UUID) -> String { source + "|round|" + id.uuidString.lowercased() }

  private func save(_ row: CalendarRoundRow, in db: Database) throws {
    if let existing = try CalendarRoundRow.find(row.id).fetchOne(db), existing.updatedAt > row.updatedAt { return }
    try CalendarRoundRow.upsert { row }.execute(db)
  }

  private func roundRow(_ race: Race, updatedAt: Date) throws -> CalendarRoundRow {
    CalendarRoundRow(id: roundKey(race.id), payload: try JSONEncoder().encode(race),
      updatedAt: updatedAt.timeIntervalSince1970)
  }

  private func scope(for query: CalendarQuery) throws -> String {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.sortedKeys]
    return source + "|schedule|" + String(decoding: try encoder.encode(query), as: UTF8.self)
  }
}
