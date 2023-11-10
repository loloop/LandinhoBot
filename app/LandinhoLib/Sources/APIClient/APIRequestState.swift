//
//  APIRequestState.swift
//
//
//  Created by Mauricio Cardozo on 10/11/23.
//

import Foundation
import ComposableArchitecture

public enum APIRequestState<T: Equatable & Decodable>: Equatable {
  case idle
  case loading
  case reloading(T)
  case finished(TaskResult<T>)
}

public extension APIRequestState {
  var isLoading: Bool {
    self == .loading
  }

  var value: T? {
    if case .finished(.success(let value)) = self {
      return value
    }
    return nil
  }
}
