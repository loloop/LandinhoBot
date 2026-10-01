import Foundation
import LandinhoFoundation

public actor SessionReminderCenter {
  public init(backend: any SessionNotificationBackend, now: @escaping @Sendable () -> Date = { Date() }) {
    self.backend = backend
    self.now = now
  }

  private let backend: any SessionNotificationBackend
  private let now: @Sendable () -> Date
  private var operationInProgress = false
  private var waitingOperations: [CheckedContinuation<Void, Never>] = []

  public func current() async -> SessionReminderSnapshot {
    await acquireOperation()
    defer { releaseOperation() }
    return await snapshot(authorization: await backend.authorization())
  }

  public func refresh(rounds: [Race]) async throws -> SessionReminderSnapshot {
    await acquireOperation()
    defer { releaseOperation() }
    let authorization = await backend.authorization()
    let pending = await backend.pending()
    var schedulingError: Error?
    for reminder in pending.reminders {
      guard let round = rounds.first(where: { $0.id == reminder.roundID }) else { continue }
      if round.isCancelled {
        await backend.remove(identifiers: [reminder.identifier])
        continue
      }
      // An absent imported session is not an explicit cancellation.
      guard let session = round.events.first(where: { $0.id == reminder.sessionID }) else { continue }
      let updated: SessionReminder
      do {
        updated = try SessionReminder.make(round: round, session: session, now: now())
      } catch {
        await backend.remove(identifiers: [reminder.identifier])
        continue
      }
      if updated != reminder {
        guard authorization == .allowed else {
          await backend.remove(identifiers: [reminder.identifier])
          continue
        }
        do {
          try await backend.add(updated)
        } catch {
          // Never leave a known obsolete start time armed after an update fails.
          await backend.remove(identifiers: [reminder.identifier])
          // Continue checking other opted-in sessions, especially cancellations.
          schedulingError = error
        }
      }
    }
    if let schedulingError { throw schedulingError }
    return await snapshot(authorization: authorization)
  }

  public func toggle(round: Race, session: RaceEvent) async throws -> SessionReminderSnapshot {
    await acquireOperation()
    defer { releaseOperation() }
    let pending = await backend.pending()
    let identifier = SessionReminder.identifierPrefix + session.id.uuidString
    if pending.reminders.contains(where: { $0.identifier == identifier }) {
      await backend.remove(identifiers: [identifier])
      return await snapshot(authorization: await backend.authorization())
    }

    _ = try SessionReminder.make(round: round, session: session, now: now())
    var authorization = await backend.authorization()
    if authorization == .notDetermined {
      let granted = try await backend.requestAuthorization()
      authorization = granted ? await backend.authorization() : .denied
    }
    guard authorization == .allowed else { throw SessionReminderError.permissionDenied }
    // Keep below iOS's pending-notification capacity, including requests from other features.
    guard (await backend.pending()).totalRequestCount < 60 else { throw SessionReminderError.limitReached }
    // The permission prompt may have stayed open past the session's start.
    let reminder = try SessionReminder.make(round: round, session: session, now: now())
    try await backend.add(reminder)
    let result = await snapshot(authorization: authorization)
    guard result.scheduledDates[session.id] != nil else { throw SessionReminderError.schedulingFailed }
    return result
  }

  private func snapshot(authorization: SessionReminderAuthorization) async -> SessionReminderSnapshot {
    let pending = await backend.pending()
    let dates = pending.reminders.filter { $0.date > now() }.reduce(into: [UUID: Date]()) {
      $0[$1.sessionID] = $1.date
    }
    return .init(authorization: authorization, scheduledDates: dates)
  }

  // Actor isolation alone permits another operation to interleave at an await.
  private func acquireOperation() async {
    if operationInProgress {
      await withCheckedContinuation { waitingOperations.append($0) }
    } else {
      operationInProgress = true
    }
  }

  private func releaseOperation() {
    if waitingOperations.isEmpty {
      operationInProgress = false
    } else {
      waitingOperations.removeFirst().resume()
    }
  }
}
