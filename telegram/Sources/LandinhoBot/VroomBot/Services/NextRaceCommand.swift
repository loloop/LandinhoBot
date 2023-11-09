//
//  NextRaceService.swift
//
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation

struct NextRaceCommand: Command {

  let command: String = "nextrace"
  let description: String = "Mostra a próxima corrida que irá acontecer"
  let api = APIClient<NextRaceResponse>(endpoint: "next-race")

  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    let categoryTag = update.arguments.first ?? ""
    let response = try await api.fetch(arguments: ["argument": categoryTag])
    guard let formattedResponse = formatResponse(response) else {
      try await bot.reply(update, text: "Não encontrei a próxima corrida")
      return
    }
    try await bot.reply(update, text: formattedResponse)
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

  struct NextRaceResponse: Codable, Equatable {
    let nextRace: Race?
    let categoryComment: String
  }
}
