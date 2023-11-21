//
//  APIRequester.swift
//
//
//  Created by Mauricio Cardozo on 30/06/23.
//

import ComposableArchitecture
import Foundation
import NotificationsQueue

@_spi(Internal) public protocol APIClientServiceProtocol: DependencyKey, TestDependencyKey {
  func request<T: Decodable>(
    _: T.Type,
    endpoint: String,
    method: String,
    data: Data?,
    queryItems: [URLQueryItem],
    headers: [String: String]) async throws -> T

  func setPersistentHeaders(_ headers: [String : String])
}

final class APIClientService: APIClientServiceProtocol {
  static var liveValue: APIClientService = APIClientService()
  public static let live: any APIClientServiceProtocol = APIClientService()

  @Dependency(\.notificationQueue) var notificationQueue

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
    // TODO: make this configurable in the app itself, or add a separate target idk
    #if DEBUG
//    let host: String = "localhost"
    let host: String = "api.vroomvroom.racing"
    #else
    let host: String = "api.vroomvroom.racing"
    #endif
    let isLocalhost = host == "localhost"
    /**
     localhost -> http not https, need to set port 8080
     **/
    // TODO: Fix config values for each environment -- maybe separate targets for ease of use?
    // let host: String = try Configuration.value(for: "BASE_URL", in: .main)

    var components = URLComponents()
    components.scheme = isLocalhost ? "http" : "https"
    components.host = host
    components.port = isLocalhost ? 8080 : 443
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
      let JSONString = String(data: response.0, encoding: .utf8)
      notificationQueue.enqueue(.critical("Erro de conexão"))
      notificationQueue.enqueue(.debug(JSONString ?? ""))
      throw APIError(
        jsonString: JSONString,
        innerError: error)
    }
  }

  func setPersistentHeaders(_ headers: [String : String]) {
     persistentHeaders = persistentHeaders.merging(headers, uniquingKeysWith: { $1 })
  }
}

struct TestAPIClientService: APIClientServiceProtocol {
  static var liveValue: TestAPIClientService = TestAPIClientService()
  public static let test: any APIClientServiceProtocol = APIClientService()

  func request<T: Decodable>(
    _: T.Type,
    endpoint: String,
    method: String,
    data: Data?,
    queryItems: [URLQueryItem],
    headers: [String: String]) async throws -> T {
      throw URLError(.cancelled)
    }

  func setPersistentHeaders(_ headers: [String : String]) {
    fatalError("`setPersistentHeaders` should not be called on `TestAPIClientService`")
  }
}

private enum APIRequestingKey: DependencyKey {
  static let liveValue: any APIClientServiceProtocol = APIClientService.live
  static var testValue: any APIClientServiceProtocol = TestAPIClientService.test
}

@_spi(Internal) public extension DependencyValues {
  var apiRequester: any APIClientServiceProtocol {
    get { self[APIRequestingKey.self] }
    set { self[APIRequestingKey.self] = newValue }
  }
}
