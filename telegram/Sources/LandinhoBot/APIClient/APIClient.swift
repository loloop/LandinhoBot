//
//  APIClient.swift
//
//
//  Created by Mauricio Cardozo on 09/11/23.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

struct APIClientError: LocalizedError {
  let message: String

  var errorDescription: String? {
    message
  }
}

struct APIClient<T: Decodable> {

  init(endpoint: String) {
    self.endpoint = endpoint
  }

  let endpoint: String

  func fetch(arguments: [String: String] = [:]) async throws -> T {
    guard let url = buildURL(path: endpoint, args: arguments) else {
      throw APIClientError(message: "Couldn't build URL")
    }

    let data = try await URLSession.shared.data(from: url)
    return try decode(data)
  }

  func post<U: Encodable>(body: U) async throws -> T {
    guard let url = buildURL(path: endpoint, args: [:]) else {
      throw APIClientError(message: "Couldn't build URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try decode(data)
  }

  func delete<U: Encodable>(body: U) async throws -> T {
    guard let url = buildURL(path: endpoint, args: [:]) else {
      throw APIClientError(message: "Couldn't build URL")
    }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONEncoder().encode(body)

    let (data, _) = try await URLSession.shared.data(for: request)
    return try decode(data)
  }

  private func decode(_ data: Data) throws -> T {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601

    do {
      return try decoder.decode(T.self, from: data)
    } catch let error {
      let result = String(data: data, encoding: .utf8) ?? "Couldn't decode JSON"
      throw APIClientError(message: """

        \(error)

        ––––

        \(result)
      """)
    }
  }

  func buildURL(path: String, args: [String: String]) -> URL? {
    var components = URLComponents()
    components.scheme = "http"
    components.host = "localhost"
    components.path = "/\(path)"
    components.port = 8080
    components.queryItems = args.map { URLQueryItem(name: $0.key, value: $0.value) }
    return components.url
  }
}
