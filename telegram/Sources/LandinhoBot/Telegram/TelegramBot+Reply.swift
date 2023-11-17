//
//  TelegramBot+Reply.swift
//  
//
//  Created by Mauricio Cardozo on 16/03/23.
//

import Foundation
import TelegramBotSDK

extension TelegramBot {
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
