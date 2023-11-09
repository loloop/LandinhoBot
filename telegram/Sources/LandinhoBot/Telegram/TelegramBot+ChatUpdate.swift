//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation
import TelegramBotSDK

extension ChatUpdate {
  init?(_ update: Update) {
    guard
      let message = update.message,
      let text = message.text,
      text.first == "/",
      case let commandsPlusArgs = text.split(whereSeparator: { $0 == " " }).map(String.init),
      let slashedCommand = commandsPlusArgs.first, /// `/nextRace@BotName`
      let splitFromAtCommand = slashedCommand.split(separator: "@").first, /// `[/nextRace, LakersBot]`
      case let command = String(splitFromAtCommand), /// `/nextRace`
      let text = message.text,
      let actualChatID = update.message?.chat.id,
      case let chatID = String(actualChatID)
    else { return nil }

    self.command = command
    self.arguments = Array(commandsPlusArgs.dropFirst())
    self.message = text
    self.chatID = chatID
    self.chatName = message.chat.username ?? message.chat.title ?? ""
  }
}
