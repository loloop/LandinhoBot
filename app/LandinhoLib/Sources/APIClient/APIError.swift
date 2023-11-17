//
//  APIError.swift
//
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import Foundation

public struct APIError: Equatable, Error {
  public static func == (lhs: APIError, rhs: APIError) -> Bool {
    lhs.jsonString == rhs.jsonString
  }

  public let jsonString: String?
  public let innerError: Error
}
