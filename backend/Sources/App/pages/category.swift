//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Vapor
import Foundation

struct UploadCategoryHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }
  var path: String { "category" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(UploadCategoryRequest.self)

    let category = Category(
      title: request.title,
      tag: request.categoryTag,
      comment: request.comment)

    try await category.create(on: req.db)

    return category
  }

  struct UploadCategoryRequest: Content {
    let title: String
    let categoryTag: String
    let comment: String?
  }
}

struct CategoryListHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "category" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    return try await Category
      .query(on: req.db)
      .sort(.sort(.custom("lower(title)"), .ascending))
      .all()
  }
}

struct UpdateCategoryHandler: AsyncRequestHandler {
  var method: HTTPMethod { .PATCH }
  var path: String { "category" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(UpdateCategoryRequest.self)
    guard let id = UUID(uuidString: request.id) else {
      throw Abort(.badRequest)
    }

    try await Category
      .query(on: req.db)
      .set(\.$title, to: request.title)
      .set(\.$tag, to: request.tag)
      .set(\.$comment, to: request.comment)
      .filter(\.$id, .equal, id)
      .update()

    return request
  }

  struct UpdateCategoryRequest: Content {
    let id: String
    let title: String
    let tag: String
    let comment: String?
  }
}
