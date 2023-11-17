//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Vapor
import Foundation

struct UploadRaceHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }
  var path: String { "race" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(UploadRaceRequest.self)

    guard request.shortTitle.count <= 23 else {
      // 23 is the exact number of characters in "Circuit of the Americas"
      throw Abort(.badRequest, reason: "Short title is too long!")
    }

    guard let category = try await Category.query(on: req.db)
      .filter(\.$tag, .equal, request.categoryTag)
      .first() else {
      throw Abort(.notFound, reason: "Category tag not found")
    }

    let events = request.events?.compactMap {
      RaceEvent(title: $0.title, date: $0.date, isMainEvent: $0.isMainEvent)
    } ?? []

    if events.isEmpty && request.earliestEventDate == nil {
      throw Abort(.badRequest, reason: "A race must have a date")
    }

    var earliestDate: Date

    if let date = request.earliestEventDate {
      earliestDate = date
    } else if let date = events.sorted(
      by: { $0.date ?? Date() > $1.date ?? Date() })
      .first?
      .date {
      earliestDate = date
    } else {
      throw Abort(.badRequest, reason: "A race must have a date")
    }

    let race = Race(
      title: request.title,
      earliestEventDate: earliestDate,
      shortTitle: request.shortTitle)

    try await req.db.transaction { db in
      try await category.$races.create(race, on: db)
      try await race.$events.create(events, on: db)
    }

    return race
  }

  struct UploadRaceRequest: Content {
    let title: String
    let shortTitle: String
    let categoryTag: String
    let events: [UploadRaceEvent]?
    let earliestEventDate: Date?

    struct UploadRaceEvent: Content {
      let title: String
      let date: Date
      let isMainEvent: Bool
    }
  }
}

struct RaceListHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "race" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let arg = try req.query.decode(RaceListQuery.self)

    return try await Race
      .query(on: req.db)
      .join(parent: \.$category)
      .filter(Category.self, \.$tag, .equal, arg.tag)
      .sort(\.$earliestEventDate, .ascending)
      .all()
  }

  struct RaceListQuery: Content {
    let tag: String
  }
}

struct UpdateRaceHandler: AsyncRequestHandler {
  var method: HTTPMethod { .PATCH }
  var path: String { "race" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(UpdateRaceRequest.self)

    guard let id = UUID(uuidString: request.id) else {
      throw Abort(.badRequest)
    }

    guard request.shortTitle.count <= 23 else {
      // 23 is the exact number of characters in "Circuit of the Americas"
      throw Abort(.badRequest, reason: "Short title is too long!")
    }

    try await Race.query(on: req.db)
      .set(\.$title, to: request.title)
      .set(\.$shortTitle, to: request.shortTitle)
      .filter(\.$id, .equal, id)
      .update()

    return request
  }

  struct UpdateRaceRequest: Content {
    let id: String
    let title: String
    let shortTitle: String
  }
}
