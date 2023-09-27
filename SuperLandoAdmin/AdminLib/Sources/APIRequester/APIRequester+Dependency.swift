//
//  APIRequester+Dependency.swift
//  
//
//  Created by Mauricio Cardozo on 02/08/23.
//

import ComposableArchitecture
import Foundation

struct TestAPIRequester: APIRequesting {
  static var liveValue: TestAPIRequester = TestAPIRequester()
  public static let test: any APIRequesting = APIRequester()

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
    fatalError("why did you call this?")
  }
}

private enum APIRequestingKey: DependencyKey {
  static let liveValue: any APIRequesting = APIRequester.live
  static var testValue: any APIRequesting = TestAPIRequester.test
}

public extension DependencyValues {
  var apiRequester: any APIRequesting {
    get { self[APIRequestingKey.self] }
    set { self[APIRequestingKey.self] = newValue }
  }
}
