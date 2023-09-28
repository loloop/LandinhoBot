//
//  AsyncRequestHandler.swift
//
//
//  Created by Mauricio Cardozo on 28/09/23.
//

import Foundation
import Vapor

// This file is part of the de-ginnyfication of the repo - We should investigate the memory issues and bring ginny back

public protocol AsyncRequestHandler {
  init()
  associatedtype Response: AsyncResponseEncodable
  var method: HTTPMethod { get }
  var path: String { get }
  func handle(req: Request) async throws -> Response
}

extension AsyncRequestHandler {
  public func register(in app: Application) {
    app.logger.info("registering \(path.pathComponents) as \(method.string)")
    app
      .on(method, path.pathComponents) { [handle] req async throws in
        return try await handle(req)
      }
  }
}

extension Array where Element == any AsyncRequestHandler {
  func register(in app: Application) {
    self.forEach {
      $0.register(in: app)
    }
  }
}
