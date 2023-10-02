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

    let events = request.events.compactMap {
      RaceEvent(title: $0.title, date: $0.date)
    }

    guard !events.isEmpty else {
      throw Abort(.badRequest)
    }

    try await req.db.transaction { db in
      try await RaceEvent
        .query(on: db)
        .join(parent: \.$race)
        .filter(Race.self, \.$id, .equal, raceID)
        .all()
        .delete(on: db)

      try await race.$events.create(events, on: db)
    }

    return events
  }

  struct SaveEventListRequest: Content {
    let raceID: String
    let events: [UploadRaceEvent]

    struct UploadRaceEvent: Content {
      let title: String
      let date: Date
    }
  }
}
