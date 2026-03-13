//
//  MySubscriptionsCommand.swift
//
//
//  Created for LandinhoBot subscription feature
//

import Foundation

struct MySubscriptionsCommand: Command {

  let command: String = "mysubscriptions"
  let description: String = "Lista as categorias que este chat acompanha"

  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    let api = APIClient<SubscriptionResponse>(endpoint: "subscriptions/\(update.chatID)")

    do {
      let response = try await api.fetch()
      if response.subscribedCategories.isEmpty {
        try await bot.reply(
          update,
          text: "Este chat não tem inscrições ativas.\nUse /subscribe seguido de uma tag para se inscrever.")
      } else {
        let categoryList = response.subscribedCategories
          .map { "• `\($0)`" }
          .joined(separator: "\n")
        try await bot.reply(
          update,
          text: "Inscrições ativas neste chat:\n\n\(categoryList)\n\nPara cancelar, use /unsubscribe seguido da tag.")
      }
    } catch {
      try await bot.reply(
        update,
        text: "Este chat não tem inscrições ativas.\nUse /subscribe seguido de uma tag para se inscrever.")
    }
  }
}
