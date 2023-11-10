//
//  APIClientReducer.swift
//
//
//  Created by Mauricio Cardozo on 30/06/23.
//

import Foundation
import ComposableArchitecture



public struct APIClient<T: Equatable & Decodable>: Reducer {
  public init() {}

  public struct State: Equatable {
    public init(endpoint: String) {
      self.baseEndpoint = endpoint
    }

    public var baseEndpoint: String
    public var response: APIRequestState<T> = .idle
    public var headers: [String: String] = [:]
  }

  public enum Action: Equatable {
    // TODO: Pagination support with `requestMore`
    // case fetchMore([URLQueryItem])

    case request(Request)
    case refresh(Request)
    case response(APIRequestState<T>)
  }

  @Dependency(\.apiRequester) var apiClient

  public var body: some ReducerOf<APIClient> {
    Reduce { state, action in
      switch action {
      case .request(let request):
        let endpoint = state.baseEndpoint
        state.response = .loading

        return .run { send in
          try await callAPIRequester(
            request: request,
            endpoint: endpoint,
            send: send)
        }

      case .refresh(let request):
        let endpoint = state.baseEndpoint
        let response = state.response

        return .run { send in
          if case .finished(let taskResult) = response {
            let innerValue = try taskResult.value
            await send(.response(.reloading(innerValue)))
          }

          try await callAPIRequester(
            request: request,
            endpoint: endpoint,
            send: send)
        }

      case .response(.finished(let result)):
        state.response = .finished(result)
        return .none

// TODO: We should somehow log the user out on unauthorized requests
//      case .response(.finished(.failure(let error))):
//        return .none

      case .response:
        return .none
      }
    }
  }

  @Sendable
  func callAPIRequester(
    request: Request,
    endpoint: String,
    send: Send<Action>)
  async throws {
    await send(
      .response(
        .finished(
          TaskResult {
            return try await apiClient.request(
              T.self,
              endpoint: endpoint,
              method: request.method,
              data: request.data,
              queryItems: request.queryItems,
              headers: request.additionalHeaders)
          }
        )))
  }
}
