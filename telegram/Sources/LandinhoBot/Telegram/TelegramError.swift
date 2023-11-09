//
//  TelegramError.swift
//
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation

struct TelegramError: LocalizedError {
  let message: String

  var errorDescription: String? { message }
}
