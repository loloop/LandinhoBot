//
//
//  DefaultVroomBot.swift
//
//
//  Created by Mauricio Cardozo on 23/10/23.
//

import Foundation

final class DefaultVroomBot: SwiftyBot {

  override init() {
    super.init()
    update()
  }

  override var commands: [Command] {
    [
      HelpCommand(),
      NextRaceCommand(),
      CategoryListCommand()
    ]
  }
}
