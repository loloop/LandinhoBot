//
//  UnsubscribeCommand.swift
//
//
//  Created for LandinhoBot subscription feature
//

import Foundation

struct UnsubscribeCommand: Command {

  let command: String = "unsubscribe"
  let description: String = "Cancela a inscrição de alertas de uma categoria"
  let api = APIClient<SubscriptionResponse>(endpoint: "subscribe")

  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    guard let tag = update.arguments.first, !tag.isEmpty else {
      try await bot.reply(
        update,
        text: "Por favor informe a tag da categoria.\nEx: /unsubscribe f1")
      return
    }

    do {
      let response = try await api.delete(
        body: SubscriptionRequest(chatID: update.chatID, categoryTag: tag))
      if response.subscribedCategories.isEmpty {
        try await bot.reply(
          update,
          text: "Inscrição em `\(tag)` cancelada. Você não tem mais inscrições ativas.")
      } else {
        let categoryList = response.subscribedCategories.joined(separator: ", ")
        try await bot.reply(
          update,
          text: "Inscrição em `\(tag)` cancelada. Inscrições restantes: \(categoryList)")
      }
    } catch {
      try await bot.reply(
        update,
        text: "Não encontrei inscrição ativa em `\(tag)` para este chat.")
    }
  }
}
