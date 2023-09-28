//
//  APIRequester.swift
//
//
//  Created by Mauricio Cardozo on 30/06/23.
//

import Foundation
import ComposableArchitecture

public protocol APIRequesting: DependencyKey, TestDependencyKey {
  func request<T: Decodable>(
    _: T.Type,
    endpoint: String,
    method: String,
    data: Data?,
    queryItems: [URLQueryItem],
    headers: [String: String]) async throws -> T

  // TODO: Maybe this should be `setMiddleware`?
  func setPersistentHeaders(_ headers: [String : String])
}

// TODO: why was this a struct in the first place?
final class APIRequester: APIRequesting {
  static var liveValue: APIRequester = APIRequester()
  public static let live: any APIRequesting = APIRequester()

  var persistentHeaders: [String: String] = [
    "Content-Type": "application/json",
    "Accept": "application/json"
  ]
  
  let decoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }()

  func makeURL(path: String, queryItems: [URLQueryItem]?) throws -> URL? {
    #if DEBUG
    // let host: String = "localhost"
    let host: String = "quake.host"
    #else
    let host: String = "myones-backend.onrender.com"
    #endif
    let isLocalhost = host == "localhost"
    /**
     localhost -> http not https, need to set port 8080
     **/
    // TODO: Fix config values for each environment -- maybe separate targets for ease of use?
    // let host: String = try Configuration.value(for: "BASE_URL", in: .main)

    var components = URLComponents()
    components.scheme = isLocalhost ? "http" : "http"
    components.host = host
//    if isLocalhost { components.port = 8080 }
    components.port = 8080
    components.path = "/\(path)"
    components.queryItems = queryItems
    return components.url
  }

  func request<T: Decodable>(
    _: T.Type,
    endpoint: String,
    method: String,
    data: Data?,
    queryItems: [URLQueryItem],
    headers: [String: String]
  ) async throws -> T {
    // TODO: makeRequest instead of makeURL???
    guard
      let url = try makeURL(path: endpoint, queryItems: queryItems)
    else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = method
    request.httpBody = data

    for header in persistentHeaders {
      request.setValue(header.value, forHTTPHeaderField: header.key)
    }

    for header in headers {
      request.setValue(header.value, forHTTPHeaderField: header.key)
    }

    let response = try await URLSession.shared.data(for: request)
    do {
      let decoded = try decoder.decode(T.self, from: response.0)
      return decoded
    } catch(let error) {
      throw URLError(.cannotParseResponse)
    }
  }

  func setPersistentHeaders(_ headers: [String : String]) {
     persistentHeaders = persistentHeaders.merging(headers, uniquingKeysWith: { $1 })
  }
}
