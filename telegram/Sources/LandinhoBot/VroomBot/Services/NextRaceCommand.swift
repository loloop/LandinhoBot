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
    do {
      let response = try await api.fetch(arguments: ["argument": categoryTag])
      let formattedResponse = formatResponse(
        response,
        showsHelpText: categoryTag.isEmpty)
      try await bot.reply(update, text: formattedResponse)
    } catch {
      try await bot.reply(update, text: "Não encontrei a próxima corrida")
    }
  }

  func formatResponse(_ response: NextRaceResponse, showsHelpText: Bool) -> String {
    return """
    \(response.category.title)
    \(response.title)
    \(formatRace(response))
    \(response.category.comment)
    \(showsHelpText ? Self.helpText : "")
    """
  }

  func formatRace(_ response: NextRaceResponse) -> String {
    let events = response.events.map(formatEvent(_:)).joined(separator: "\n")
    guard !events.isEmpty else { return formatEventlessRace(race: response) }
    return """

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    \(events)

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    """
  }

  func formatEvent(_ event: RaceEvent) -> String {
    "\(Self.formatter.string(from: event.date)) – \(event.title)"
  }

  func formatEventlessRace(race: NextRaceResponse) -> String {
    """

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    \(Self.formatter.string(from: race.earliestEventDate))

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    """
  }

  static let helpText = """
  Procura a próxima corrida de outra categoria? Digite o comando `/nextrace` seguido da tag da categoria que você está procurando, ex.:

  `/nextrace f1`
  """

  static let formatter = {
    let f = DateFormatter()
    f.dateFormat = "dd/MM 'as' HH:mm"
    return f
  }()

  struct NextRaceResponse: Codable, Equatable {
    let id: UUID
    let title: String
    let earliestEventDate: Date
    let events: [RaceEvent]
    let category: Category
  }
}
