//
//  Bot.swift
//
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation

public protocol Bot {
  func reply(_ update: ChatUpdate, text: String) async throws
}
