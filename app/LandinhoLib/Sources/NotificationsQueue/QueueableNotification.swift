//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 21/11/23.
//

import Foundation

public struct QueueableNotification: Equatable & Identifiable {
  public let id = UUID()
  let text: String
  let type: NotificationQueueClient.`Type`
}

public extension QueueableNotification {
  static func debug(_ text: String) -> Self {
    .init(text: text, type: .debug)
  }

  static func testflight(_ text: String) -> Self {
    .init(text: text, type: .testflight)
  }

  static func warning(_ text: String) -> Self {
    .init(text: text, type: .warning)
  }

  static func critical(_ text: String) -> Self {
    .init(text: text, type: .critical)
  }

  static func success(_ text: String) -> Self {
    .init(text: text, type: .success)
  }
}
