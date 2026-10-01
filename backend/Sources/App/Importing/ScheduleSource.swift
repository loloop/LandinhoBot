import Foundation
import Vapor

struct SourceSession: Codable, Equatable {
  let id: String
  let title: String
  let date: Date?
  let scheduledDay: String?
  let isMainEvent: Bool
  let isCancelled: Bool
}

struct SourceMeeting: Codable, Equatable {
  let id: String
  let title: String
  let shortTitle: String
  let sourceURL: String
  let startDate: Date
  let endDate: Date
  let isCancelled: Bool
  let sessions: [SourceSession]
}

struct ImportIssue: Codable, Equatable {
  let title: String
  let message: String
  let sourceURL: String?
  var recordID: UUID? = nil
  var sourceID: String? = nil
  var recordKind: String? = nil
  var parentID: UUID? = nil
  var candidates: [ImportCandidate] = []
}

struct ImportCandidate: Codable, Equatable {
  let id: UUID
  let title: String
}

struct ScheduleSnapshot {
  let meetings: [SourceMeeting]
  // Discovery includes rejected meetings, so a fetch failure is not a disappearance.
  let discoveredURLs: Set<String>
  let issues: [ImportIssue]
}

protocol ScheduleProvider {
  var id: String { get }
  var categoryTag: String { get }
  func fetch(client: Client, now: Date) async throws -> ScheduleSnapshot
}

struct ImportChange: Codable, Equatable {
  let recordID: UUID
  let title: String
  let field: String
  let before: String?
  let after: String?
  let sourceURL: String?
}

enum ScheduleDates {
  static func parse(_ value: String) -> Date? {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
  }

  static func string(_ date: Date?) -> String? {
    date.map { ISO8601DateFormatter().string(from: $0) }
  }
}
