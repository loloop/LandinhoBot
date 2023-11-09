//
//  HelpCommand.swift
//  
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation

struct HelpCommand: Command {
  let command: String = "help"
  let description: String = "Ajuda para todos os comandos"
  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws {
    try await bot.reply(update, text: helpText)
  }

  let helpText = """
Os comandos disponíveis são:

/help
Lista os comandos de ajuda

/nextrace [categoria]
Lista a próxima corrida que vai acontecer. Passe uma categoria para que ele liste a próxima corrida de uma categoria específica.

/categories
Lista as categorias disponíveis
"""
}
