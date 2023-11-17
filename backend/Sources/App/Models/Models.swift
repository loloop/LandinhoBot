//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 24/09/23.
//

import Fluent
import Vapor

final class Category: Model, Content {
  static var schema: String = "category"

  init() {}

  init(
    id: UUID = UUID(),
    title: String,
    tag: String,
    comment: String?)
  {
    self.id = id
    self.title = title
    self.tag = tag
    self.comment = comment
  }

  @ID(key: .id)
  var id: UUID?

  @Field(key: "title")
  var title: String?

  @Field(key: "tag")
  var tag: String?

  @Field(key: "comment")
  var comment: String?

  @Children(for: \.$category)
  var races: [Race]
}

final class Race: Model, Content {
  static var schema: String = "race"

  init() {}

  init(
    id: UUID = UUID(),
    title: String,
    earliestEventDate: Date,
    shortTitle: String
  )
  {
    self.id = id
    self.title = title
    self.earliestEventDate = earliestEventDate
    self.shortTitle = shortTitle
  }

  @ID(key: .id)
  var id: UUID?

  @Field(key: "title")
  var title: String?

  @Field(key: "short_title")
  var shortTitle: String?

  @Field(key: "earliest_event_date")
  var earliestEventDate: Date

  @Parent(key: "category")
  var category: Category

  @Children(for: \.$race)
  var events: [RaceEvent]
}

final class RaceEvent: Model, Content {
  static var schema: String = "race_event"

  init() {}

  init(
    id: UUID = UUID(),
    title: String,
    date: Date,
    isMainEvent: Bool
  )
  {
    self.id = id
    self.title = title
    self.date = date
    self.isMainEvent = isMainEvent
  }

  @ID(key: .id)
  var id: UUID?

  @Field(key: "title")
  var title: String?

  @Field(key: "date")
  var date: Date?

  @Field(key: "is_main_event")
  var isMainEvent: Bool

  @Parent(key: "race")
  var race: Race
}

final class Chat: Model {
  static var schema: String = "chat"

  init() {}

  @ID(key: .id)
  var id: UUID?

  @Field(key: "chat_id")
  var chatID: String?

  // TODO: Should this be a sibling relationship?
  @Field(key: "subbed_to")
  var subscribedCategories: [String]
}
