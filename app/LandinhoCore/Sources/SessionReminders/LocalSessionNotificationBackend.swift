import Foundation
import UserNotifications

public struct LocalSessionNotificationBackend: SessionNotificationBackend {
  public init() {}

  public func authorization() async -> SessionReminderAuthorization {
    let settings = await UNUserNotificationCenter.current().notificationSettings()
    switch settings.authorizationStatus {
    case .notDetermined: return .notDetermined
    case .authorized, .provisional, .ephemeral: return .allowed
    case .denied: return .denied
    @unknown default: return .denied
    }
  }

  public func requestAuthorization() async throws -> Bool {
    try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
  }

  public func pending() async -> PendingSessionReminders {
    let requests = await UNUserNotificationCenter.current().pendingNotificationRequests()
    let reminders = requests.compactMap { request -> SessionReminder? in
      guard request.identifier.hasPrefix(SessionReminder.identifierPrefix),
        let roundString = request.content.userInfo["roundID"] as? String,
        let roundID = UUID(uuidString: roundString),
        let sessionID = UUID(uuidString: String(request.identifier.dropFirst(SessionReminder.identifierPrefix.count))),
        let trigger = request.trigger as? UNCalendarNotificationTrigger,
        let date = trigger.nextTriggerDate()
      else { return nil }
      return .init(roundID: roundID, sessionID: sessionID, date: date,
                   title: request.content.title, body: request.content.body)
    }
    return .init(reminders: reminders, totalRequestCount: requests.count)
  }

  public func add(_ reminder: SessionReminder) async throws {
    let content = UNMutableNotificationContent()
    content.title = reminder.title
    content.body = reminder.body
    content.sound = .default
    content.threadIdentifier = reminder.roundID.uuidString
    content.userInfo = ["roundID": reminder.roundID.uuidString, "sessionID": reminder.sessionID.uuidString]
    let trigger = UNCalendarNotificationTrigger(dateMatching: reminder.dateComponents, repeats: false)
    guard trigger.nextTriggerDate() == reminder.date else { throw SessionReminderError.schedulingFailed }
    try await UNUserNotificationCenter.current().add(
      UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
  }

  public func remove(identifiers: [String]) async {
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
  }
}
