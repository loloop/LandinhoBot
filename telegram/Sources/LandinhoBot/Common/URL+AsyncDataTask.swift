//
//  URL+AsyncDataTask.swift
//  
//
//  Created by Mauricio Cardozo on 23/10/23.
//

import Foundation
#if os(Linux)
import FoundationNetworking
#endif

extension URLSession {
  func data(url: URL) async throws -> Data {
    try await withCheckedThrowingContinuation { continuation in
      let request = URLRequest(url: url)
      let task = dataTask(with: request) { data, _, error in
        guard let data else {
          if let error {
            continuation.resume(throwing: error)
          }
          return
        }

        continuation.resume(returning: data)
      }
      task.resume()
    }
  }
}
