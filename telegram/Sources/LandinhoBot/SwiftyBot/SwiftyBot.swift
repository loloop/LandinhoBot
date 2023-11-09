import Foundation
#if os(Linux)
import FoundationNetworking
#endif
import TelegramBotSDK

open class SwiftyBot {

  public init() {
    self._bot = TelegramBot(token: Environment.telegramToken)
    self.bot = _bot

    registerCommands()
  }

  public let bot: Bot
  // TODO: Make the internal bot more generic so we can support other platforms in the future
  let _bot: TelegramBot

  open var commands: [Command] {
    fatalError("Please subclass SwiftyBot")
  }

  private func registerCommands() {
    let cmds = commands.map(\.botCommand)

    guard !cmds.isEmpty else {
      debugMessage("`commands` should not be empty")
      return
    }

    _bot.setMyCommandsAsync(commands: cmds) { [unowned self] result, error in
      debugMessage("SET COMMANDS ASYNC")

      if let error {
        debugMessage("ERROR: \(error.debugDescription)")
      }
    }
  }

  public func update() {
    while let update = _bot.nextUpdateSync() {
      guard
        let chatUpdate = ChatUpdate(update),
        let cmd = commands.first(where: {
          chatUpdate.command == "/\($0.command.lowercased())"
        })
      else {
        continue
      }

      firehose(chatUpdate)
      Task {
        try await cmd.handle(
          update: chatUpdate,
          bot: bot,
          debugMessage: { [weak self] str in
            self?.debugMessage(str)
          }
        )
      }
    }
  }

  private func firehose(_ update: ChatUpdate) {
    debugMessage(
      """
      \(update.command) called by \(update.chatID) - \(update.chatName)
      """,
      currentUpdate: update)
  }

  public func debugMessage(_ message: String, currentUpdate: ChatUpdate? = nil) {
    Task {
      guard
        let chatIDString = Environment.debugChatID,
        let chatID = Int64(chatIDString)
      else {
        if let currentUpdate {
          try await bot.reply(
            currentUpdate,
            text: "Firehose not set! Current chat ID: \(currentUpdate.chatID)")
        }
        return
      }

      try await _bot.sendMessageAsync(chatId: .chat(chatID), text: message)
    }
  }
}
