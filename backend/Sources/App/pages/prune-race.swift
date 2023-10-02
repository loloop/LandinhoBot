//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 02/10/23.
//

import Foundation
import Vapor
import Fluent

struct PruneRaceHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "prune-race" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let arg = try req.query.decode(RaceListQuery.self)

    try await req.db.transaction { db in
      let races = try await Race
        .query(on: db)
        .join(parent: \.$category)
        .filter(Category.self, \.$tag, .equal, arg.tag)
        .filter(\.$earliestEventDate, .lessThan, Date())
        .with(\.$events)
        .all()

      for r in races {
        try await r.$events.query(on: db).delete()
        try await r.delete(on: db)
      }
    }

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

