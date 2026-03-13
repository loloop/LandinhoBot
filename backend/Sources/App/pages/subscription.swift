//
//  subscription.swift
//
//
//  Created for LandinhoBot subscription feature
//

import Vapor
import Foundation

// MARK: - POST /subscribe

struct SubscribeHandler: AsyncRequestHandler {
  var method: HTTPMethod { .POST }
  var path: String { "subscribe" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(SubscriptionRequest.self)

    // Validate category exists
    guard try await Category.query(on: req.db)
      .filter(\.$tag, .equal, request.categoryTag)
      .first() != nil
    else {
      throw Abort(.notFound, reason: "Category '\(request.categoryTag)' not found")
    }

    if let chat = try await Chat.query(on: req.db)
      .filter(\.$chatID, .equal, request.chatID)
      .first()
    {
      if !chat.subscribedCategories.contains(request.categoryTag) {
        chat.subscribedCategories.append(request.categoryTag)
        try await chat.save(on: req.db)
      }
      return SubscriptionResponse(
        chatID: chat.chatID ?? "",
        subscribedCategories: chat.subscribedCategories)
    } else {
      let chat = Chat()
      chat.chatID = request.chatID
      chat.subscribedCategories = [request.categoryTag]
      try await chat.create(on: req.db)
      return SubscriptionResponse(
        chatID: request.chatID,
        subscribedCategories: [request.categoryTag])
    }
  }
}

// MARK: - DELETE /subscribe

struct UnsubscribeHandler: AsyncRequestHandler {
  var method: HTTPMethod { .DELETE }
  var path: String { "subscribe" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let request = try req.content.decode(SubscriptionRequest.self)

    guard let chat = try await Chat.query(on: req.db)
      .filter(\.$chatID, .equal, request.chatID)
      .first()
    else {
      throw Abort(.notFound, reason: "No subscriptions found for this chat")
    }

    chat.subscribedCategories.removeAll { $0 == request.categoryTag }
    try await chat.save(on: req.db)

    return SubscriptionResponse(
      chatID: chat.chatID ?? "",
      subscribedCategories: chat.subscribedCategories)
  }
}

// MARK: - GET /subscriptions/:chatId

struct ChatSubscriptionsHandler: AsyncRequestHandler {
  var method: HTTPMethod { .GET }
  var path: String { "subscriptions/:chatId" }

  func handle(req: Request) async throws -> some AsyncResponseEncodable {
    let chatID = req.parameters.get("chatId") ?? ""

    guard let chat = try await Chat.query(on: req.db)
      .filter(\.$chatID, .equal, chatID)
      .first()
    else {
      return SubscriptionResponse(chatID: chatID, subscribedCategories: [])
    }

    return SubscriptionResponse(
      chatID: chatID,
      subscribedCategories: chat.subscribedCategories)
  }
}

// MARK: - Shared types

struct SubscriptionRequest: Content {
  let chatID: String
  let categoryTag: String
}

struct SubscriptionResponse: Content {
  let chatID: String
  let subscribedCategories: [String]
}
