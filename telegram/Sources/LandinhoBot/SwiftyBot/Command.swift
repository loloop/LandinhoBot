//
//  Command.swift
//
//
//  Created by Mauricio Cardozo on 23/10/23.
//

public struct Command {
  let command: String
  let description: String
  let handler: (ChatUpdate) async throws -> Void

  public init(
    command: String,
    description: String,
    handler: @escaping (ChatUpdate) async throws -> Void)
  {
    /// A bot command **must** be lowercased
    let sanitizedCommand = command.lowercased()

    if description.isEmpty {
      fatalError("Command description must be non-empty")
    }

    self.command = sanitizedCommand
    self.description = description
    self.handler = handler
  }
}
