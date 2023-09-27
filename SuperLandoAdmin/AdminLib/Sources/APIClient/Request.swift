//
//  Request.swift
//  
//
//  Created by Mauricio Cardozo on 02/08/23.
//

import Foundation

public struct Request: Equatable {
  var data: Data?
  var additionalHeaders: [String: String]
  var queryItems: [URLQueryItem]
  var method: String
}

public extension Request {
  static func post(_ data: Encodable, additionalHeaders: [String: String] = [:]) throws -> Self {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let encodedData = try encoder.encode(data)
    return Request(
      data: encodedData,
      additionalHeaders: additionalHeaders,
      queryItems: [],
      method: "POST")
  }

  static func patch(_ data: Encodable, additionalHeaders: [String: String] = [:]) throws -> Self {
    let encodedData = try JSONEncoder().encode(data)
    return Request(
      data: encodedData,
      additionalHeaders: additionalHeaders,
      queryItems: [],
      method: "PATCH")
  }

  static func get(queryItems: [URLQueryItem] = []) -> Self {
    return Request(
      data: nil,
      additionalHeaders: [:],
      queryItems: queryItems,
      method: "GET")
  }

  static var get: Self {
    Request(
      data: nil,
      additionalHeaders: [:],
      queryItems: [],
      method: "GET")
  }

  static func delete(_ data: Codable, additionalHeaders: [String: String] = [:]) throws -> Self {
    let encodedData = try JSONEncoder().encode(data)
    return Request(
      data: encodedData,
      additionalHeaders: additionalHeaders,
      queryItems: [],
      method: "DELETE")
  }
}
