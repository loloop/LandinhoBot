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

  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    // TODO: bater na API e pegar uma lista de todas as categorias disponíveis

    try await bot.reply(update, text: "TODO")
  }
}
