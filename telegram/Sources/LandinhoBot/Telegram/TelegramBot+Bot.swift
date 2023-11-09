//
//  Telegram+Bot.swift
//
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation
import TelegramBotSDK

extension TelegramBot: Bot {
  public func reply(_ update: ChatUpdate, text: String) async throws {
    guard let chatID = Int64(update.chatID) else {
      throw TelegramError(message: "Couldn't convert chatID String to Int64")
    }
    try await sendMessageAsync(
      chatId: .chat(chatID),
      text: text,
      parseMode: .markdownv2)
  }
}
