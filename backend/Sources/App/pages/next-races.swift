//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 17/11/23.
//

import Foundation
import Vapor
import Fluent

struct NextRacesHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "next-races" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let currentDate = Date()

    var categoryTag: String
    do {
      categoryTag = try req.query.decode(NextRacesRequest.self).category
    } catch {
      categoryTag = ""
    }

    let query = Race
      .query(on: req.db)
      .filter(\.$earliestEventDate, .greaterThanOrEqual, currentDate)
      .join(parent: \.$category)
      .sort(\.$earliestEventDate, .ascending)
      .with(\.$events)
      .with(\.$category)

    if !categoryTag.isEmpty {
      query.filter(Category.self, \.$tag, .equal, categoryTag)
    }

    return try await query.paginate(for: req)
  }

  struct NextRacesRequest: Content {
    let category: String
  }
}
