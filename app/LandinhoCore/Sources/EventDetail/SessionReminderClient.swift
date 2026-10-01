import ComposableArchitecture
import LandinhoFoundation
import SessionReminders

public struct SessionReminderClient {
  public var current: @Sendable () async -> SessionReminderSnapshot
  public var refresh: @Sendable ([Race]) async throws -> SessionReminderSnapshot
  public var toggle: @Sendable (Race, RaceEvent) async throws -> SessionReminderSnapshot
}

extension SessionReminderClient: DependencyKey {
  public static let liveValue: Self = {
    let center = SessionReminderCenter(backend: LocalSessionNotificationBackend())
    return .init(
      current: { await center.current() },
      refresh: { try await center.refresh(rounds: $0) },
      toggle: { try await center.toggle(round: $0, session: $1) })
  }()

  public static let testValue = Self(
    current: { .init(authorization: .notDetermined, scheduledDates: [:]) },
    refresh: { _ in .init(authorization: .notDetermined, scheduledDates: [:]) },
    toggle: { _, _ in throw SessionReminderError.schedulingFailed })
}

public extension DependencyValues {
  var sessionReminders: SessionReminderClient {
    get { self[SessionReminderClient.self] }
    set { self[SessionReminderClient.self] = newValue }
  }
}
