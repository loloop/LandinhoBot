//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Foundation
import Vapor

struct NextRaceHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "next-race" }
  
  @Sendable
  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    var args: String
    do {
      args = try req.query.decode(NextRaceRequest.self).argument
    } catch {
      args = ""
    }

    let currentDate = Date()

    let query = Race
      .query(on: req.db)
      .filter(\.$earliestEventDate, .greaterThanOrEqual, currentDate)
      .join(parent: \.$category)
      .sort(\.$earliestEventDate, .ascending)
      .with(\.$events)
      .with(\.$category)

    if !args.isEmpty {
      query.filter(Category.self, \.$tag, .equal, args)
    }

    let nextRace = try await query.first()

    return NextRaceResponse(
      nextRace: nextRace,
      categoryComment: nextRace?.category.comment ?? "")
  }

  struct NextRaceRequest: Content {
    let argument: String
  }

  struct NextRaceResponse: Content {
    let nextRace: Race?
    let categoryComment: String
  }
}

