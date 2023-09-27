//
//  Environment.swift
//  
//
//  Created by Mauricio Cardozo on 15/03/23.
//

import Foundation

enum Environment {
  static let telegramToken = Environment.readEnv(from: "TELEGRAM_TOKEN")

  private static func readEnv(from: String) -> String {
    let envVar = ProcessInfo.processInfo.environment[from]
    guard let envVar, !envVar.isEmpty else {
      fatalError("Could not read variable on \(from)")
    }
    return envVar
  }
}
