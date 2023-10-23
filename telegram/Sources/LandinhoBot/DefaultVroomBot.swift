//
//
//  DefaultVroomBot.swift
//
//
//  Created by Mauricio Cardozo on 23/10/23.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import TelegramBotSDK

final class DefaultVroomBot: SwiftyBot {

  override init() {
    super.init()
    update()
  }

  struct NextRaceResponse: Codable, Equatable {
    let nextRace: Race?
    let categoryComment: String
  }

  override var commands: [Command] {
    [
      .init(
        command: "nextrace",
        description: "Shows when the next race will happen",
        handler: { update in
          try await self.handleNextRace(update: update)
        })
    ]
  }

  func handleNextRace(update: ChatUpdate) async throws {
    let categoryTag = update.arguments.first ?? ""

    guard
      let url = self.buildURL(path: "next-race", args: ["argument": categoryTag])
    else {
      try await bot.reply(update, text: "Internal error")
      return
    }

    let data = try await URLSession.shared.data(url: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    do {
      let response = try decoder.decode(NextRaceResponse.self, from: data)
      guard let formattedRace = formatResponse(response) else {
        try await bot.reply(update, text: "Couldn't find next race")
        return
      }
      try await bot.reply(update, text: formattedRace)
    } catch (let error) {
      try await bot.reply(update, text: "\(error)")
    }
  }

  func buildURL(path: String, args: [String: String]) -> URL? {
    var components = URLComponents()
    components.scheme = "http"
    components.host = "localhost"
    components.path = "/\(path)"
    components.port = 8080
    components.queryItems = args.map { URLQueryItem(name: $0.key, value: $0.value) }
    return components.url
  }

  func formatResponse(_ response: NextRaceResponse) -> String? {
    guard let nextRace = response.nextRace else { return nil }

    return """
    \(nextRace.title)
    \(formatRace(nextRace))
    \(response.categoryComment)
    """
  }

  func formatRace(_ race: Race) -> String {
    let events = race.events.map(formatEvent(_:)).joined(separator: "\n")
    guard !events.isEmpty else { return formatEventlessRace(race: race) }
    return """
    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    \(events)

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    """
  }

  func formatEvent(_ event: RaceEvent) -> String {
    "\(Self.formatter.string(from: event.date)) - \(event.title)"
  }

  func formatEventlessRace(race: Race) -> String {
    """

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    \(Self.formatter.string(from: race.earliestEventDate))
    
    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    """
  }

  static let formatter = {
    let f = DateFormatter()
    f.dateFormat = "dd/MM 'as' HH:mm"
    return f
  }()
}
