//
//  upcoming-alerts.swift
//
//
//  Created for LandinhoBot subscription feature
//

import Vapor
import Foundation

// MARK: - GET /upcoming-alerts

struct UpcomingAlertsHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "upcoming-alerts" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let thresholdSeconds: Double
    if let thresholdParam = try? req.query.decode(UpcomingAlertsRequest.self) {
      thresholdSeconds = Double(thresholdParam.threshold)
    } else {
      thresholdSeconds = 3600
    }

    let now = Date()
    let upperBound = now.addingTimeInterval(thresholdSeconds)

    let events = try await RaceEvent.query(on: req.db)
      .filter(\.$date, .greaterThanOrEqual, now)
      .filter(\.$date, .lessThanOrEqual, upperBound)
      .with(\.$race) { raceQuery in
        raceQuery.with(\.$category)
      }
      .all()

    // Fetch all chats once and filter in memory
    let allChats = try await Chat.query(on: req.db).all()

    let alertItems: [AlertItem] = events.compactMap { event in
      guard
        let eventDate = event.date,
        let eventTitle = event.title,
        let raceTitle = event.race.title,
        let raceShortTitle = event.race.shortTitle,
        let categoryTag = event.race.category.tag,
        let categoryTitle = event.race.category.title
      else { return nil }

      let chatIDs = allChats
        .filter { $0.subscribedCategories.contains(categoryTag) }
        .compactMap { $0.chatID }

      guard !chatIDs.isEmpty else { return nil }

      return AlertItem(
        chatIDs: chatIDs,
        categoryTag: categoryTag,
        categoryTitle: categoryTitle,
        raceTitle: raceTitle,
        raceShortTitle: raceShortTitle,
        eventTitle: eventTitle,
        eventDate: eventDate)
    }

    return alertItems
  }

  struct UpcomingAlertsRequest: Content {
    let threshold: Int
  }
}

// MARK: - Response type

struct AlertItem: Content {
  let chatIDs: [String]
  let categoryTag: String
  let categoryTitle: String
  let raceTitle: String
  let raceShortTitle: String
  let eventTitle: String
  let eventDate: Date
}
