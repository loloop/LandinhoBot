import Fluent
import Vapor

struct ImportSettings: Content {
  let categoryTag: String
  let provider: String?
  let enabled: Bool
  let intervalDays: Int
  let lastImportAt: Date?
  let nextImportAt: Date?

  init(_ category: Category) {
    categoryTag = category.tag ?? ""
    provider = category.importProvider
    enabled = category.importsEnabled
    intervalDays = category.importIntervalDays
    lastImportAt = category.lastImportAt
    nextImportAt = category.nextImportAt
  }
}

struct ImportSettingsHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "import-settings" }
  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let tag = try req.query.get(String.self, at: "category")
    guard let category = try await Category.query(on: req.db).filter(\.$tag == tag).first()
    else { throw Abort(.notFound) }
    return ImportSettings(category)
  }
}

struct UpdateImportSettingsHandler: AsyncRequestHandler {
  var method: HTTPMethod { .PATCH }
  var path: String { "import-settings" }
  struct Input: Content { let categoryTag: String; let enabled: Bool; let intervalDays: Int }
  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let input = try req.content.decode(Input.self)
    guard (1...365).contains(input.intervalDays) else { throw Abort(.badRequest, reason: "Interval must be between 1 and 365 days") }
    return try await req.application.scheduleImporter.withLock(tag: input.categoryTag, db: req.db) { db in
      guard let category = try await Category.query(on: db).filter(\.$tag == input.categoryTag).first()
      else { throw Abort(.notFound) }
      guard category.importProvider != nil || !input.enabled else { throw Abort(.badRequest, reason: "No provider available") }
      category.importsEnabled = input.enabled
      category.importIntervalDays = input.intervalDays
      category.nextImportAt = category.lastImportAt.map { $0.addingTimeInterval(Double(input.intervalDays) * 86400) } ?? Date()
      try await category.save(on: db)
      return ImportSettings(category)
    }
  }
}

struct RefreshImportHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }
  var path: String { "import-refresh" }
  struct Input: Content { let categoryTag: String }
  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let input = try req.content.decode(Input.self)
    return try await req.application.scheduleImporter.refresh(tag: input.categoryTag, trigger: "manual", db: req.db, client: req.client)
  }
}

struct ImportHistoryHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "imports" }
  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let tag = try req.query.get(String.self, at: "category")
    return try await ImportRun.query(on: req.db).filter(\.$categoryTag == tag)
      .sort(\.$startedAt, .descending).paginate(for: req)
  }
}

struct ResolveImportMatchHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }
  var path: String { "import-match" }
  struct Input: Content { let runID: UUID; let issueIndex: Int; let recordID: UUID }
  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let input = try req.content.decode(Input.self)
    guard let run = try await ImportRun.find(input.runID, on: req.db) else { throw Abort(.notFound) }
    return try await req.application.scheduleImporter.withLock(tag: run.categoryTag, db: req.db) { db in
      guard run.issues.indices.contains(input.issueIndex) else { throw Abort(.badRequest) }
      let issue = run.issues[input.issueIndex]
      guard let sourceID = issue.sourceID, issue.candidates.contains(where: { $0.id == input.recordID }),
        let category = try await Category.query(on: db).filter(\.$tag == run.categoryTag).first()
      else { throw Abort(.badRequest) }
      if issue.recordKind == "meeting" {
        guard let race = try await Race.find(input.recordID, on: db), race.$category.id == category.id,
          race.sourceID == nil || race.sourceID == sourceID
        else { throw Abort(.conflict) }
        if let linked = try await Race.query(on: db).filter(\.$category.$id == category.requireID())
          .filter(\.$sourceID == sourceID).first(), linked.id != race.id {
          throw Abort(.conflict, reason: "This source meeting is already linked to another record")
        }
        race.sourceID = sourceID
        race.sourceURL = issue.sourceURL
        try await race.save(on: db)
      } else if issue.recordKind == "session" {
        guard let event = try await Race.find(issue.parentID, on: db), event.$category.id == category.id,
          let session = try await RaceEvent.find(input.recordID, on: db), session.$race.id == event.id,
          session.sourceID == nil || session.sourceID == sourceID
        else { throw Abort(.conflict) }
        if let linked = try await RaceEvent.query(on: db).filter(\.$race.$id == event.requireID())
          .filter(\.$sourceID == sourceID).first(), linked.id != session.id {
          throw Abort(.conflict, reason: "This source session is already linked to another record")
        }
        session.sourceID = sourceID
        session.sourceURL = issue.sourceURL
        try await session.save(on: db)
      } else { throw Abort(.badRequest) }
      return ImportSettings(category)
    }
  }
}
