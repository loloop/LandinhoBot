import AdminSession
import ComposableArchitecture
import Foundation
#if canImport(UIKit)
import UIKit
#endif

public struct AdminAccessClient: DependencyKey {
  public var unlock: @Sendable (String) async throws -> Void
  public var lock: @Sendable () -> Void

  public init(unlock: @escaping @Sendable (String) async throws -> Void, lock: @escaping @Sendable () -> Void) {
    self.unlock = unlock
    self.lock = lock
  }

  public static let liveValue: Self = {
    _ = AdminAccessLifecycle.shared
    return Self(unlock: { password in
      let attempt = liveAdminSession.beginUnlock()
      let response = try await APIClientService.live.request(AdminVerification.self,
        endpoint: "admin-session", method: "GET", data: nil, queryItems: [],
        headers: ["Authorization": AdminSession.header(password: password)])
      try Task.checkCancellation()
      guard response.authorized, liveAdminSession.completeUnlock(password: password, attempt: attempt) else {
        throw CancellationError()
      }
    }, lock: lockLiveAdminSession)
  }()

  public static let testValue = Self(unlock: { _ in throw CancellationError() }, lock: {})
}

public extension DependencyValues {
  var adminAccess: AdminAccessClient {
    get { self[AdminAccessClient.self] }
    set { self[AdminAccessClient.self] = newValue }
  }
}

public extension Notification.Name {
  static let landinhoAdminLocked = Self("LandinhoAdminLocked")
}

let liveAdminSession = AdminSession()

func lockLiveAdminSession() {
  liveAdminSession.lock()
  NotificationCenter.default.post(name: .landinhoAdminLocked, object: nil)
}

private struct AdminVerification: Decodable { let authorized: Bool }

private final class AdminAccessLifecycle {
  static let shared = AdminAccessLifecycle()
  private var backgroundObserver: NSObjectProtocol?

  private init() {
    #if canImport(UIKit)
    backgroundObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil
    ) { _ in lockLiveAdminSession() }
    #endif
  }
}
