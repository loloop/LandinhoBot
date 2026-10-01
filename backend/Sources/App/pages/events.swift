//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 02/10/23.
//

import Foundation
import Vapor
import Fluent

struct EventListHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "events" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let arg = try req.query.decode(RaceListQuery.self)

    guard let id = UUID(uuidString: arg.id) else {
      throw Abort(.notFound)
    }

    return try await RaceEvent
      .query(on: req.db)
      .join(parent: \.$race)
      .filter(Race.self, \.$id, .equal, id)
      .sort(\.$date, .ascending)
      .all()
  }

  struct RaceListQuery: Content {
    let id: String
  }
}

struct UpdateEventsHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }
  var path: String { "events" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(SaveEventListRequest.self)

    guard
      let raceID = UUID(uuidString: request.raceID),
      let race = try await Race.find(raceID, on: req.db)
    else {
      throw Abort(.notFound)
    }

    try await req.db.transaction { db in
      let existing = try await race.$events.query(on: db).all()
      var retained = Set<UUID>()
      for input in request.events {
        guard !input.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw Abort(.badRequest) }
        let event: RaceEvent
        if let id = input.id {
          guard retained.insert(id).inserted else { throw Abort(.badRequest, reason: "Duplicate session ID") }
          if let match = existing.first(where: { $0.id == id }) { event = match }
          else {
            // New app-side UUIDs are accepted only when they do not belong to another race.
            guard try await RaceEvent.find(id, on: db) == nil else { throw Abort(.badRequest) }
            event = RaceEvent(id: id, title: input.title, date: input.date, isMainEvent: input.isMainEvent)
          }
        } else {
          let matches = existing.filter { $0.title == input.title && !retained.contains($0.id!) }
          event = matches.count == 1 ? matches[0] : RaceEvent(title: input.title, date: input.date, isMainEvent: input.isMainEvent)
          retained.insert(try event.requireID())
        }
        event.$race.id = raceID
        event.title = input.title
        event.date = input.date
        event.isMainEvent = input.isMainEvent
        event.isCancelled = input.isCancelled ?? event.isCancelled
        try await event.save(on: db)
      }
      for event in existing where !retained.contains(try event.requireID()) {
        if event.sourceID != nil {
          // A manual removal lasts until the next authoritative import; keep its identity.
          event.isCancelled = true
          try await event.save(on: db)
        } else { try await event.delete(on: db) }
      }
      let dates = request.events.filter { $0.isCancelled != true }.compactMap(\.date)
      if race.sourceID == nil {
        race.earliestEventDate = dates.min() ?? race.earliestEventDate
        race.scheduleEndDate = dates.max() ?? race.scheduleEndDate
        try await race.save(on: db)
      }
    }

    return try await race.$events.query(on: req.db).sort(\.$date).all()
  }

  struct SaveEventListRequest: Content {
    let raceID: String
    let events: [UploadRaceEvent]

    struct UploadRaceEvent: Content {
      let id: UUID?
      let title: String
      let date: Date?
      let isMainEvent: Bool
      let isCancelled: Bool?
    }
  }
}
