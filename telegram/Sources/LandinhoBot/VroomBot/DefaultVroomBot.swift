//
//
//  DefaultVroomBot.swift
//
//
//  Created by Mauricio Cardozo on 23/10/23.
//

import Foundation

final class DefaultVroomBot: SwiftyBot {

  // Lazy so _bot is available after super.init()
  private lazy var alertDispatcher = AlertDispatcher(bot: _bot)

  override init() {
    super.init()
    alertDispatcher.start()
    update()
  }

  override var commands: [Command] {
    [
      HelpCommand(),
      NextRaceCommand(),
      CategoryListCommand(),
      SubscribeCommand(),
      UnsubscribeCommand(),
      MySubscriptionsCommand()
    ]
  }
}
