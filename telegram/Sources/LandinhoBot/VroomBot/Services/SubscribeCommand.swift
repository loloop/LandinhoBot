//
//  SubscribeCommand.swift
//
//
//  Created for LandinhoBot subscription feature
//

import Foundation

struct SubscribeCommand: Command {

  let command: String = "subscribe"
  let description: String = "Inscreve o chat em alertas de uma categoria"
  let subscribeAPI = APIClient<SubscriptionResponse>(endpoint: "subscribe")
  let categoriesAPI = APIClient<[Category]>(endpoint: "category")

  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    guard let tag = update.arguments.first, !tag.isEmpty else {
      let categories = (try? await categoriesAPI.fetch()) ?? []
      let tagList = categories.map { "`\($0.tag)`" }.joined(separator: ", ")
      let hint = tagList.isEmpty ? "" : "\n\nCategorias disponíveis: \(tagList)"
      try await bot.reply(update, text: "Por favor informe a tag da categoria.\nEx: /subscribe f1\(hint)")
      return
    }

    do {
      let response = try await subscribeAPI.post(
        body: SubscriptionRequest(chatID: update.chatID, categoryTag: tag))
      let categoryList = response.subscribedCategories.joined(separator: ", ")
      try await bot.reply(
        update,
        text: "Inscrito com sucesso na categoria `\(tag)`!\nSuas inscrições: \(categoryList)")
    } catch {
      try await bot.reply(
        update,
        text: "Categoria `\(tag)` não encontrada. Use /categories para ver as disponíveis.")
    }
  }
}
