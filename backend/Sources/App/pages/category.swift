//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Vapor
import Foundation
import Ginny

struct UploadCategoryHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(UploadCategoryRequest.self)

    let category = Category(
      title: request.title,
      tag: request.categoryTag,
      comment: request.comment)

    try await category.create(on: req.db)

    return request
  }

  struct UploadCategoryRequest: Content {
    let title: String
    let categoryTag: String
    let comment: String?
  }
}
