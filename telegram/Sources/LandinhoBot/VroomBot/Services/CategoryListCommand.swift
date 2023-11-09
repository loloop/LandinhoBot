//
//  CategoryListCommand.swift
//
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation

struct CategoryListCommand: Command {

  let command: String = "categories"
  let description: String = "Lista todas as categorias disponíveis"
  let api = APIClient<[Category]>(endpoint: "category")

  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    let result = try await api.fetch()
    let formattedResult = formatCategories(result)
    try await bot.reply(update, text: formattedResult)
  }

  func formatCategories(_ categories: [Category]) -> String {
    guard !categories.isEmpty else {
      return "Não encontrei nenhuma categoria"
    }

    let categoryList = categories
      .map { "`\($0.tag)` – \($0.title)" }
      .joined(separator: "\n")

    return """
    As categorias disponíveis são:

    \(categoryList)
    """
  }
}
