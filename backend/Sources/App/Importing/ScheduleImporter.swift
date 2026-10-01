import Fluent
import SQLKit
import Vapor

struct ScheduleImporter {
  let providers: [any ScheduleProvider]

  init(providers: [any ScheduleProvider] = [FormulaOneProvider()]) {
    self.providers = providers
  }

  func refresh(tag: String, trigger: String, db: Database, client: Client, now: Date = Date()) async throws -> ImportRun {
    try await withLock(tag: tag, db: db) { connection in
      guard let category = try await Category.query(on: connection).filter(\.$tag == tag).first(),
        let provider = providers.first(where: { $0.id == category.importProvider && $0.categoryTag == tag })
      else { throw Abort(.notFound, reason: "No schedule provider configured for this category") }
      if trigger == "scheduled", (!category.importsEnabled || (category.nextImportAt.map { $0 > now } ?? false)) {
        throw Abort(.conflict, reason: "Category is not due for an import")
      }
      let run = ImportRun(categoryTag: tag, provider: provider.id, trigger: trigger, now: now)
      try await run.create(on: connection)
      do {
        let snapshot = try await provider.fetch(client: client, now: now)
        try await apply(snapshot: snapshot, category: category, run: run, db: connection, now: now)
      } catch {
        run.status = "failed"
        run.issues.append(.init(title: "Import failed", message: String(describing: error), sourceURL: nil))
      }
      run.finishedAt = Date()
      try await run.save(on: connection)
      category.lastImportAt = run.finishedAt
      category.nextImportAt = run.finishedAt?.addingTimeInterval(Double(category.importIntervalDays) * 86400)
      try await category.save(on: connection)
      return run
    }
  }

  func withLock<T>(tag: String, db: Database, operation: @Sendable @escaping (Database) async throws -> T) async throws -> T {
    try await db.withConnection { connection in
      guard let sql = connection as? any SQLDatabase,
        let row = try await sql.raw("SELECT pg_try_advisory_lock(hashtext(\(bind: "landinho-import:" + tag))) AS acquired").first(),
        try row.decode(column: "acquired", as: Bool.self)
      else { throw Abort(.conflict, reason: "An import is already running for this category") }
      do {
        let result = try await operation(connection)
        try await sql.raw("SELECT pg_advisory_unlock(hashtext(\(bind: "landinho-import:" + tag)))").run()
        return result
      } catch {
        try await sql.raw("SELECT pg_advisory_unlock(hashtext(\(bind: "landinho-import:" + tag)))").run()
        throw error
      }
    }
  }

  // Testable with a supplied snapshot; each meeting and its audit diff commit together.
  func apply(snapshot: ScheduleSnapshot, category: Category, run: ImportRun, db: Database, now: Date) async throws {
    run.issues = snapshot.issues
    let categoryID = try category.requireID()
    let duplicateIDs = Dictionary(grouping: snapshot.meetings, by: \.id).filter { $0.value.count > 1 }.keys
    for meeting in snapshot.meetings {
      do {
        guard !duplicateIDs.contains(meeting.id), meeting.endDate >= meeting.startDate,
          !meeting.title.isEmpty,
          Set(meeting.sessions.map(\.id)).count == meeting.sessions.count
        else { throw Abort(.unprocessableEntity, reason: "Invalid or duplicate meeting") }
        let result = try await db.transaction { transaction -> ([ImportChange], [ImportIssue]) in
          var changes: [ImportChange] = []
          var issues: [ImportIssue] = []
          let existing = try await Race.query(on: transaction).filter(\.$category.$id == categoryID).with(\.$events).all()
          var race = existing.first { $0.sourceID == meeting.id }
          if meeting.endDate < now && (race?.scheduleEndDate ?? race?.earliestEventDate ?? .distantPast) < now {
            return ([], [])
          }
          if race == nil {
            let nearby = existing.filter { $0.sourceID == nil && abs($0.earliestEventDate.timeIntervalSince(meeting.startDate)) <= 7 * 86400 }
            let clear = nearby.filter {
              Self.name($0.title ?? "") == Self.name(meeting.title) || Self.name($0.shortTitle ?? "") == Self.name(meeting.shortTitle)
            }
            if clear.count == 1 { race = clear[0] }
            else if !nearby.isEmpty {
              issues.append(.init(title: meeting.title, message: "Choose which existing meeting matches this source meeting",
                sourceURL: meeting.sourceURL, sourceID: meeting.id, recordKind: "meeting",
                candidates: nearby.compactMap { r in r.id.map { .init(id: $0, title: r.title ?? r.shortTitle ?? "Meeting") } }))
              return ([], issues)
            }
          }
          let isNew = race == nil
          let record = race ?? Race(title: meeting.title, earliestEventDate: meeting.startDate, shortTitle: meeting.shortTitle)
          let raceID = try record.requireID()
          if isNew { changes.append(.init(recordID: raceID, title: meeting.title, field: "meeting", before: nil, after: "added", sourceURL: meeting.sourceURL)) }
          else {
            change(&changes, id: raceID, title: meeting.title, field: "title", before: record.title, after: meeting.title, url: meeting.sourceURL)
            change(&changes, id: raceID, title: meeting.title, field: "shortTitle", before: record.shortTitle, after: meeting.shortTitle, url: meeting.sourceURL)
            change(&changes, id: raceID, title: meeting.title, field: "startDate", before: ScheduleDates.string(record.earliestEventDate), after: ScheduleDates.string(meeting.startDate), url: meeting.sourceURL)
            change(&changes, id: raceID, title: meeting.title, field: "endDate", before: ScheduleDates.string(record.scheduleEndDate), after: ScheduleDates.string(meeting.endDate), url: meeting.sourceURL)
            change(&changes, id: raceID, title: meeting.title, field: "isCancelled", before: String(record.isCancelled), after: String(meeting.isCancelled), url: meeting.sourceURL)
          }
          record.$category.id = categoryID
          record.title = meeting.title
          record.shortTitle = meeting.shortTitle
          record.earliestEventDate = meeting.startDate
          record.scheduleEndDate = meeting.endDate
          record.sourceID = meeting.id
          record.sourceURL = meeting.sourceURL
          record.isCancelled = meeting.isCancelled
          record.importWarning = nil
          try await record.save(on: transaction)
          let oldEvents = isNew ? [] : record.events
          var touched = Set<UUID>()
          for session in meeting.sessions {
            var event = oldEvents.first { $0.sourceID == session.id }
            if event == nil {
              let candidates = oldEvents.filter { $0.sourceID == nil && Self.name($0.title ?? "") == Self.name(session.title) }
              if candidates.count == 1 { event = candidates[0] }
              else if candidates.count > 1 {
                issues.append(.init(title: session.title, message: "Choose which existing session matches this source session",
                  sourceURL: meeting.sourceURL, sourceID: session.id, recordKind: "session", parentID: raceID,
                  candidates: candidates.compactMap { e in e.id.map { .init(id: $0, title: e.title ?? "Session") } }))
                continue
              }
            }
            let added = event == nil
            let item = event ?? RaceEvent(title: session.title, date: session.date, isMainEvent: session.isMainEvent)
            let eventID = try item.requireID()
            touched.insert(eventID)
            if added { changes.append(.init(recordID: eventID, title: session.title, field: "session", before: nil, after: ScheduleDates.string(session.date) ?? "added (time pending)", sourceURL: meeting.sourceURL)) }
            else {
              change(&changes, id: eventID, title: session.title, field: "title", before: item.title, after: session.title, url: meeting.sourceURL)
              change(&changes, id: eventID, title: session.title, field: "date", before: ScheduleDates.string(item.date), after: ScheduleDates.string(session.date), url: meeting.sourceURL)
              change(&changes, id: eventID, title: session.title, field: "scheduledDay", before: item.scheduledDay, after: session.scheduledDay, url: meeting.sourceURL)
              change(&changes, id: eventID, title: session.title, field: "isMainEvent", before: String(item.isMainEvent), after: String(session.isMainEvent), url: meeting.sourceURL)
              change(&changes, id: eventID, title: session.title, field: "isCancelled", before: String(item.isCancelled), after: String(session.isCancelled), url: meeting.sourceURL)
            }
            item.$race.id = raceID
            item.title = session.title
            item.date = session.date
            item.scheduledDay = session.scheduledDay
            item.isMainEvent = session.isMainEvent
            item.isCancelled = session.isCancelled
            item.sourceID = session.id
            item.sourceURL = meeting.sourceURL
            item.importWarning = nil
            try await item.save(on: transaction)
          }
          for event in oldEvents where !touched.contains(try event.requireID()) {
            event.importWarning = "Not found in the latest import"
            try await event.save(on: transaction)
            issues.append(.init(title: event.title ?? "Session", message: event.importWarning!, sourceURL: meeting.sourceURL, recordID: event.id))
          }
          // Persist this meeting's audit data within its transaction, including partial runs.
          try await ImportRun.query(on: transaction).filter(\.$id == run.requireID())
            .set(\.$changes, to: run.changes + changes)
            .set(\.$issues, to: run.issues + issues)
            .update()
          return (changes, issues)
        }
        run.changes.append(contentsOf: result.0)
        run.issues.append(contentsOf: result.1)
      } catch {
        run.issues.append(.init(title: meeting.title, message: String(describing: error), sourceURL: meeting.sourceURL))
      }
    }
    let races = try await Race.query(on: db).filter(\.$category.$id == categoryID).all()
    for race in races where (race.scheduleEndDate ?? race.earliestEventDate) >= now {
      if race.sourceURL.map({ snapshot.discoveredURLs.contains($0) }) == true { continue }
      race.importWarning = "Not found in the latest import"
      try await race.save(on: db)
      run.issues.append(.init(title: race.title ?? "Meeting", message: race.importWarning!, sourceURL: race.sourceURL, recordID: race.id))
    }
    run.status = run.issues.isEmpty ? "completed" : "partial"
    try await run.save(on: db)
  }

  private func change(_ changes: inout [ImportChange], id: UUID, title: String, field: String, before: String?, after: String?, url: String) {
    guard before != after else { return }
    changes.append(.init(recordID: id, title: title, field: field, before: before, after: after, sourceURL: url))
  }

  private static func name(_ title: String) -> String {
    title.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
      .replacingOccurrences(of: "treino livre", with: "practice")
      .replacingOccurrences(of: "classificacao", with: "qualifying")
      .replacingOccurrences(of: "corrida", with: "race")
      .replacingOccurrences(of: "sprint shootout", with: "sprint qualifying")
      .filter { $0.isLetter || $0.isNumber }
  }
}
