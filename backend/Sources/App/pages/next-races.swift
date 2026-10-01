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
    let input = try req.query.decode(NextRacesRequest.self)
    let page = input.page ?? 1
    let per = input.per ?? 10
    guard (1...1_000_000).contains(page), (1...100).contains(per) else {
      throw Abort(.badRequest, reason: "page must be positive and per must be between 1 and 100")
    }
    let favorites = try input.favoriteTags()
    let now = Date()
    func query() -> QueryBuilder<Race> {
      let query = upcomingRaces(on: req.db, now: now)
        .join(parent: \.$category)
        .sort(\.$earliestEventDate, .ascending)
        .sort(\.$id, .ascending)
        .with(\.$events)
        .with(\.$category)
      if let category = input.category, !category.isEmpty {
        query.filter(Category.self, \.$tag, .equal, category)
      }
      return query
    }
    guard !favorites.isEmpty, input.category?.isEmpty != false else {
      return try await query().paginate(.init(page: page, per: per))
    }

    // Page the two partitions together, so every favorite round precedes every
    // other round, including favorites that would fall beyond the first page.
    let total = try await query().count()
    let favoriteCount = try await query().filter(Category.self, \.$tag ~~ favorites).count()
    let start = (page - 1) * per
    let end = min(start + per, total)
    var items: [Race] = []
    if start < min(end, favoriteCount) {
      items = try await query().filter(Category.self, \.$tag ~~ favorites)
        .range(start..<min(end, favoriteCount)).all()
    }
    if end > max(start, favoriteCount) {
      items += try await query().filter(Category.self, \.$tag !~ favorites)
        .range(max(0, start - favoriteCount)..<(end - favoriteCount)).all()
    }
    return Page(items: items, metadata: .init(page: page, per: per, total: total))
  }

  struct NextRacesRequest: Content {
    let category: String?
    let favorites: String?
    let page: Int?
    let per: Int?

    func favoriteTags() throws -> [String] {
      guard let favorites, !favorites.isEmpty else { return [] }
      let tags = favorites.split(separator: ",", omittingEmptySubsequences: false).map(String.init)
      let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
      guard tags.count <= 100, tags.allSatisfy({ !$0.isEmpty && $0.utf8.count <= 64 && $0.unicodeScalars.allSatisfy(allowed.contains) }) else {
        throw Abort(.badRequest, reason: "Invalid favorite category tags")
      }
      return Array(Set(tags)).sorted()
    }
  }
}
