//
//  TelegramBot+Reply.swift
//  
//
//  Created by Mauricio Cardozo on 16/03/23.
//

import Foundation
import TelegramBotSDK

struct TelegramError: Error {
  let message: String
}

extension TelegramBot {
  @discardableResult
  func reply(_ update: ChatUpdate, text: String) async throws -> Message {
    guard let chatID = Int64(update.chatID) else {
      throw TelegramError(message: "Couldn't convert chatID String to Int64")
    }
    return try await sendMessageAsync(
      chatId: .chat(chatID),
      text: text)
  }

  @discardableResult
  func sendMessageAsync(
    chatId: ChatId,
    text: String,
    parseMode: ParseMode? = nil,
    disableWebPagePreview: Bool? = nil,
    disableNotification: Bool? = nil,
    replyToMessageId: Int? = nil,
    replyMarkup: ReplyMarkup? = nil,
    _ parameters: [String: Encodable?] = [:],
    queue: DispatchQueue = .main
    ) async throws -> Message
  {
    try await withCheckedThrowingContinuation { continuation in
      sendMessageAsync(
        chatId: chatId,
        text: text,
        parseMode: parseMode,
        disableWebPagePreview: disableWebPagePreview,
        disableNotification: disableNotification,
        replyToMessageId: replyToMessageId,
        replyMarkup: replyMarkup,
        parameters,
        queue: queue) { result, error in
          if let error {
            continuation.resume(throwing: TelegramError(message: error.debugDescription))
          } else if let result {
            continuation.resume(returning: result)
          }
        }
    }
  }
}
