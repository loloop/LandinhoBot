//
//  F1Calendar.swift
//  
//
//  Created by Mauricio Cardozo on 15/03/23.
//

import Foundation

let calendarURL = URL(string: "https://raw.githubusercontent.com/calendariof1/calendariof1/main/f1-2023-dates.json")!

struct F1CalendarEvent: Codable {
  let raceName, circuitName: String
  let eventType: EventType?
  let teamLogoURL: String?
  let times: [Time]
  let location: String?

  enum CodingKeys: String, CodingKey {
    case raceName, circuitName, eventType
    case teamLogoURL = "teamLogoUrl"
    case times, location
  }
}

enum EventType: String, Codable {
  case carLaunch = "car-launch"
  case preSeasonTesting = "pre-season-testing"
}

// MARK: - Time
struct Time: Codable {
  let gmtDiff, startTime, endTime: String
  let brlStartTime, brlEndTime, porStartTime, porEndTime: String?

  enum CodingKeys: String, CodingKey {
    case gmtDiff, startTime, endTime
    case brlStartTime = "BRLStartTime"
    case brlEndTime = "BRLEndTime"
    case porStartTime = "PORStartTime"
    case porEndTime = "POREndTime"
  }
}

extension F1CalendarEvent {
  // With our current API there's no way to figure out if an event is a sprint weekend or not, so we're hardcoding the confirmed sprint weekends and checking for them here
  var isSprint_🔥🔥__HACK__🔥🔥: Bool {
    return [
      "azerbaijan",
      "austria",
      "belgium",
      "qatar",
      "united states",
      "brazil"
    ].contains(self.location)
  }
}

