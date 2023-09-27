//
//  TelegramBot+Reply.swift
//  
//
//  Created by Mauricio Cardozo on 16/03/23.
//

import Foundation
import TelegramBotSDK

extension TelegramBot {
  func reply(_ update: Update, text: String) {
    guard let message = update.message else { return }
    sendMessageSync(
      chatId: .chat(message.chat.id),
      text: text)
  }
}
