import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import TelegramBotSDK

open class SwiftyBot {

  public init() {
    self.bot = TelegramBot(token: Environment.telegramToken)
    registerCommands()
  }

  public let bot: TelegramBot

  // let env: Environment

  open var commands: [Command] {
    fatalError("Please subclass SwiftyBot")
  }

  private func registerCommands() {
    let cmds = commands.map(\.botCommand)

    guard !cmds.isEmpty else {
      debugMessage("`commands` should not be empty")
      return
    }

    bot.setMyCommandsAsync(commands: cmds) { [unowned self] result, error in
      debugMessage("SET COMMANDS ASYNC")
      if let error {
        switch error {
        case .invalidRequest:
          debugMessage("ERROR: .invalidRequest")
        case .libcurlInitError:
          debugMessage("ERROR: .libcurlInitError")
        case .libcurlError(_, description: let description):
          debugMessage("ERROR: .libcurlError: \(description)")
        case .libcurlAbortedByCallback:
          debugMessage("ERROR: .libcurlAbortedByCallback")
        case .invalidStatusCode(_, telegramDescription: let telegramDescription, _, _):
          debugMessage("ERROR: .invalidStatusCode: \(telegramDescription)")
        case .noDataReceived:
          debugMessage("ERROR: .noDataReceived")
        case .serverError:
          debugMessage("ERROR: .serverError")
        case .decodeError:
          debugMessage("ERROR: .decodeError")
        }
      }
    }
  }

  public func update() {
    while let update = bot.nextUpdateSync() {
      guard
        let message = update.message,
        let (invokedCommand, args) = destructureCommandArgs(message.text)
      else {
        continue
      }
      debugMessage("\(args.joined(separator: " ")) called")
      invokedCommand.handler(update, args)
    }
  }

  private func destructureCommandArgs(_ text: String?) -> (Command, [String])? {
    guard let text, text.first == "/" else {
      return nil
    }

    let commandPlusArgs = text.split { $0 == " " }.map(String.init)

    guard let command = commands.first(
      where: { "/\($0.command)" == commandPlusArgs[0] }
    ) else {
      return nil
    }

    return (command, commandPlusArgs)
  }

  public func debugMessage(_ message: String) {
//    guard
//      let chatID = Int64(env.debugChatID)
//    else {
//      fatalError("Could not convert token to Int64")
//    }
//
//    env.telegramBot.sendMessageSync(
//      chatId: .chat(chatID),
//      text: message)
  }
}

struct ChatUpdate {
  let command: String
  let arguments: String
  let message: String
  let chatID: String
}

public struct Command {
  let command: String
  let description: String
  // TODO: Remove the `Update` dependency
  let handler: (Update, [String]) -> Void

  public init(
    command: String,
    description: String,
    handler: @escaping (Update, [String]) -> Void)
  {
    /// A bot command **must** be lowercased
    let sanitizedCommand = command.lowercased()

    if description.isEmpty {
      fatalError("Command description must be non-empty")
    }

    self.command = sanitizedCommand
    self.description = description
    self.handler = handler
  }

  var botCommand: BotCommand {
    .init(
      command: command,
      description: description)
  }
}

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
        handler: { update, args in
          // TODO: refactor swifty bot to handle async closures
          Task {
            try await self.handleNextRace(update: update, args: args)
          }
        })
    ]
  }

  func handleNextRace(update: Update, args: [String]) async throws {
    var categoryTag = args.dropFirst().first ?? ""

    guard
      let url = self.buildURL(path: "next-race", args: ["argument": categoryTag])
    else {
      return
    }

    let data = try await URLSession.shared.data(url: url)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let response = try decoder.decode(NextRaceResponse.self, from: data)
    guard let formattedRace = formatRace(response: response) else { return }
    bot.reply(update, text: formattedRace)
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

  func formatRace(response: NextRaceResponse) -> String? {
    guard let nextRace = response.nextRace else { return nil }

    return
"""
\(nextRace.title)

🏎️🏎️🏎️🏎️🏎️🏎️🏎️

\(nextRace.events.map(formatEvent(_:)).joined(separator: "\n"))

🏎️🏎️🏎️🏎️🏎️🏎️🏎️

\(response.categoryComment)
"""
  }

  func formatEvent(_ event: RaceEvent) -> String {
    "\(Self.formatter.string(from: event.date)) \(event.title)"
  }

  static let formatter = {
    let f = DateFormatter()
    return f
  }()
}

extension URLSession {
  func data(url: URL) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      let request = URLRequest(url: url)
      self.dataTask(with: request) { data, _, error in
        guard let data else {
          if let error {
            continuation.resume(throwing: error)
          }
          return
        }

        continuation.resume(returning: data)
      }.resume()
    }
  }
}
