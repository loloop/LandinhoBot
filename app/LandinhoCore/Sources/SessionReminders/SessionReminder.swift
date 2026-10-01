import Foundation
import LandinhoFoundation

public enum SessionReminderAuthorization: Equatable, Sendable {
  case notDetermined, allowed, denied
}

public enum SessionReminderError: Error, Equatable {
  case cancelled, pendingTime, alreadyStarted, permissionDenied, limitReached, schedulingFailed
}

public struct SessionReminder: Equatable, Sendable {
  public static let identifierPrefix = "landinho.session."

  public init(roundID: UUID, sessionID: UUID, date: Date, title: String, body: String) {
    self.roundID = roundID
    self.sessionID = sessionID
    // Calendar notification triggers have second precision.
    self.date = Date(timeIntervalSince1970: floor(date.timeIntervalSince1970))
    self.title = title
    self.body = body
  }

  public let roundID: UUID
  public let sessionID: UUID
  public let date: Date
  public let title: String
  public let body: String

  public var identifier: String { Self.identifierPrefix + sessionID.uuidString }

  public var dateComponents: DateComponents {
    // Pin the instant to UTC: travelling or daylight-saving changes must not move a session.
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
    components.calendar = calendar
    components.timeZone = calendar.timeZone
    return components
  }

  public static func make(round: Race, session: RaceEvent, now: Date) throws -> Self {
    guard !round.isCancelled, !session.isCancelled else { throw SessionReminderError.cancelled }
    guard let date = session.date else { throw SessionReminderError.pendingTime }
    guard floor(date.timeIntervalSince1970) > now.timeIntervalSince1970 else {
      throw SessionReminderError.alreadyStarted
    }
    return Self(
      roundID: round.id,
      sessionID: session.id,
      date: date,
      title: "\(session.title) vai começar",
      body: "\(round.category.title) · \(round.shortTitle).")
  }
}

public struct SessionReminderSnapshot: Equatable, Sendable {
  public init(authorization: SessionReminderAuthorization, scheduledDates: [UUID: Date]) {
    self.authorization = authorization
    self.scheduledDates = scheduledDates
  }

  public let authorization: SessionReminderAuthorization
  public let scheduledDates: [UUID: Date]
}

public struct PendingSessionReminders: Sendable {
  public init(reminders: [SessionReminder], totalRequestCount: Int) {
    self.reminders = reminders
    self.totalRequestCount = totalRequestCount
  }

  public let reminders: [SessionReminder]
  public let totalRequestCount: Int
}

public protocol SessionNotificationBackend: Sendable {
  func authorization() async -> SessionReminderAuthorization
  func requestAuthorization() async throws -> Bool
  func pending() async -> PendingSessionReminders
  func add(_ reminder: SessionReminder) async throws
  func remove(identifiers: [String]) async
}
