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

    let escapedText = escapeCharacters(in: text)
    try await sendMessageAsync(
      chatId: .chat(chatID),
      text: escapedText,
      parseMode: .markdownv2)
  }

  private func escapeCharacters(in text: String) -> String {
    // Inefficient but gets the job done
    let charactersToEscape = ["_", "*", "[", "]", "(", ")", "~", "`", ">", "#", "+", "-", "=", "|", "{", "}", ".", "!"]
    return charactersToEscape.reduce(text) { partialResult, character in
      partialResult.replacingOccurrences(of: character, with: #"\"#+character)
    }
  }

}
