//
//  SwiftyBot+Telegram.swift
//
//
//  Created by Mauricio Cardozo on 23/10/23.
//

import TelegramBotSDK

extension Command {
  var botCommand: BotCommand {
    if description.isEmpty { fatalError("Command description should not be empty") }

    return .init(
      command: command.lowercased(),
      description: description)
  }
}
