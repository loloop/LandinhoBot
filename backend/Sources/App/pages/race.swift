//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Vapor
import Foundation

public protocol AsyncRequestHandler {
  init()
  associatedtype Response: AsyncResponseEncodable
  var method: HTTPMethod { get }
  func handle(req: Request) async throws -> Response
}

struct UploadRaceHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(UploadRaceRequest.self)

    guard let category = try await Category.query(on: req.db)
      .filter(\.$tag, .equal, request.categoryTag)
      .first() else {
      throw Abort(.notFound, reason: "Category tag not found")
    }

    let events = request.events.map {
      RaceEvent(title: $0.title, date: $0.date)
    }

    guard !events.isEmpty else {
      throw Abort(.badRequest, reason: "A race must have events")
    }

    guard
      let earliestDate = events.sorted(
        by: { $0.date ?? Date() > $1.date ?? Date() })
        .first?
        .date
    else {
      throw Abort(.badRequest)
    }

    let race = Race(
      title: request.title,
      earliestEventDate: earliestDate)

    try await req.db.transaction { db in
      try await category.$races.create(race, on: db)
      try await race.$events.create(events, on: db)
    }

    return request
  }

  struct UploadRaceRequest: Content {
    let title: String
    let categoryTag: String
    let events: [UploadRaceEvent]

    struct UploadRaceEvent: Content {
      let title: String
      let date: Date
    }
  }
}

