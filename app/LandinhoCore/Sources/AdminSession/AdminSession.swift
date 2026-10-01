import Foundation

/// An in-memory credential. A lock also invalidates any password verification in flight.
public final class AdminSession: @unchecked Sendable {
  public init() {}
  private let mutex = NSLock()
  private var authorization: String?
  private var attempt = UUID()

  public func beginUnlock() -> UUID {
    mutex.lock(); defer { mutex.unlock() }
    authorization = nil
    attempt = UUID()
    return attempt
  }

  @discardableResult
  public func completeUnlock(password: String, attempt: UUID) -> Bool {
    mutex.lock(); defer { mutex.unlock() }
    guard self.attempt == attempt else { return false }
    authorization = Self.header(password: password)
    return true
  }

  public func lock() {
    mutex.lock(); defer { mutex.unlock() }
    authorization = nil
    attempt = UUID()
  }

  public func header(endpoint: String, method: String) -> String? {
    guard Self.requiresAdmin(endpoint: endpoint, method: method) else { return nil }
    mutex.lock(); defer { mutex.unlock() }
    return authorization
  }

  public static func header(password: String) -> String {
    "Basic " + Data("admin:\(password)".utf8).base64EncodedString()
  }

  public static func requiresAdmin(endpoint: String, method: String) -> Bool {
    switch endpoint {
    case "admin-session", "prune-race", "import-settings", "imports", "import-refresh", "import-match":
      return true
    case "category", "race", "events":
      return method.uppercased() != "GET"
    default:
      return false
    }
  }
}
