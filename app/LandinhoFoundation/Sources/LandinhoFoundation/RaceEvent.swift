//
//  File.swift
//  
//
//  Created by Mauricio Cardozo on 14/11/23.
//

import Foundation

public struct RaceEvent: Codable, Equatable, Identifiable, Hashable {
  public init(id: UUID, title: String, date: Date?, isMainEvent: Bool, isCancelled: Bool = false, scheduledDay: String? = nil, sourceURL: String? = nil) {
    self.id = id
    self.title = title
    self.date = date
    self.isMainEvent = isMainEvent
    self.isCancelled = isCancelled
    self.scheduledDay = scheduledDay
    self.sourceURL = sourceURL
  }
  
  public let id: UUID
  public let title: String
  public let date: Date?
  public let isMainEvent: Bool
  public let isCancelled: Bool
  public let scheduledDay: String?
  public let sourceURL: String?

  public var timeLabel: String {
    if isCancelled { return "Cancelado" }
    return date?.formatted(.dateTime.hour().minute()) ?? "Horário pendente"
  }

  public var dayLabel: String {
    if let date { return date.formatted(.dateTime.day().month(.twoDigits)) }
    if let scheduledDay {
      let parts = scheduledDay.split(separator: "-")
      if parts.count == 3 { return "\(parts[2])/\(parts[1])" }
    }
    return "Data pendente"
  }

  enum CodingKeys: String, CodingKey { case id, title, date, isMainEvent, isCancelled, scheduledDay, sourceURL }

  public init(from decoder: Decoder) throws {
    let values = try decoder.container(keyedBy: CodingKeys.self)
    id = try values.decode(UUID.self, forKey: .id)
    title = try values.decode(String.self, forKey: .title)
    date = try values.decodeIfPresent(Date.self, forKey: .date)
    isMainEvent = try values.decode(Bool.self, forKey: .isMainEvent)
    isCancelled = try values.decodeIfPresent(Bool.self, forKey: .isCancelled) ?? false
    scheduledDay = try values.decodeIfPresent(String.self, forKey: .scheduledDay)
    sourceURL = try values.decodeIfPresent(String.self, forKey: .sourceURL)
  }
}
