//
//  Command.swift
//
//
//  Created by Mauricio Cardozo on 23/10/23.
//

public protocol Command {
  var command: String { get }
  var description: String { get }
  func handle(update: ChatUpdate, bot: Bot, debugMessage: (String) -> Void) async throws
}
