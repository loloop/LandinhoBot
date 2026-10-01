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
    \(response.category.comment ?? "")
    \(response.events.isEmpty || response.events.contains(where: { $0.date == nil && $0.isCancelled != true }) ? "Ainda não conseguimos obter todos os horários. Consulte a programação oficial." : "")
    \(response.sourceURL ?? "")
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
    if event.isCancelled == true { return "Cancelado – \(event.title)" }
    guard let date = event.date else { return "Horário pendente – \(event.title)" }
    return "\(Self.formatter.string(from: date)) – \(event.title)"
  }

  func formatEventlessRace(race: NextRaceResponse) -> String {
    """

    🏎️🏎️🏎️🏎️🏎️🏎️🏎️

    \(race.earliestEventDate.formatted(date: .long, time: .omitted))

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
    let sourceURL: String?
  }
}
