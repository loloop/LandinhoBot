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
    let color = try validatedCategoryColor(request.color)

    let category = Category(
      title: request.title,
      tag: request.categoryTag,
      comment: request.comment,
      color: color)

    try await category.create(on: req.db)

    return category
  }

  struct UploadCategoryRequest: Content {
    let title: String
    let categoryTag: String
    let comment: String?
    let color: String?
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
    let color = try validatedCategoryColor(request.color)
    guard let id = UUID(uuidString: request.id) else {
      throw Abort(.badRequest)
    }

    guard let category = try await Category.find(id, on: req.db) else {
      throw Abort(.notFound)
    }
    category.title = request.title
    category.tag = request.tag
    category.comment = request.comment
    // Legacy clients omit this field; explicit null restores the automatic color.
    if request.updatesColor { category.color = color }
    try await category.save(on: req.db)
    return category
  }

  struct UpdateCategoryRequest: Content {
    let id: String
    let title: String
    let tag: String
    let comment: String?
    let color: String?
    let updatesColor: Bool

    private enum CodingKeys: String, CodingKey {
      case id, title, tag, comment, color
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      id = try container.decode(String.self, forKey: .id)
      title = try container.decode(String.self, forKey: .title)
      tag = try container.decode(String.self, forKey: .tag)
      comment = try container.decodeIfPresent(String.self, forKey: .comment)
      color = try container.decodeIfPresent(String.self, forKey: .color)
      updatesColor = container.contains(.color)
    }
  }
}

/// Only opaque sRGB colors are accepted; alpha, short hex and named colors are rejected.
func validatedCategoryColor(_ color: String?) throws -> String? {
  guard let color else { return nil }
  guard color.utf8.count == 7, color.first == "#",
    color.dropFirst().utf8.allSatisfy({
      (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0)
    })
  else { throw Abort(.badRequest, reason: "Category color must be #RRGGBB") }
  return color.uppercased()
}
