@testable import App
import XCTVapor

final class AdminAccessTests: XCTestCase {
  func testPublicCategoryKeepsItsColorWithoutImportConfiguration() throws {
    let category = App.Category(title: "Formula 1", tag: "f1", comment: nil, color: "#E34B43")
    category.importProvider = "official-f1"
    category.importsEnabled = true
    let data = try JSONEncoder().encode(category)
    let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    XCTAssertEqual(json["color"] as? String, "#E34B43")
    XCTAssertEqual(json["tag"] as? String, "f1")
    XCTAssertNil(json["importProvider"])
    XCTAssertNil(json["importsEnabled"])
    XCTAssertNil(json["importIntervalDays"])
  }

  private let password = "a-test-only-password:with-utf8-ç"
  private let protectedRoutes: [(HTTPMethod, String)] = [
    (.GET, "admin-session"), (.POST, "category"), (.PATCH, "category"),
    (.POST, "race"), (.PATCH, "race"), (.POST, "events"), (.GET, "prune-race"),
    (.GET, "import-settings"), (.PATCH, "import-settings"), (.POST, "import-refresh"),
    (.GET, "imports"), (.POST, "import-match")
  ]

  func testAllAdministrativeRoutesRejectMissingWrongAndMalformedCredentials() throws {
    let app = Application(.testing); defer { app.shutdown() }
    registerRoutes(in: app, adminPassword: password)
    for (method, path) in protectedRoutes {
      for header in [nil, "Bearer anything", "Basic not-base64", basic("wrong"), basic(password, username: "someone")] as [String?] {
        try app.test(method, path, beforeRequest: {
          if let header { $0.headers.replaceOrAdd(name: .authorization, value: header) }
        }, afterResponse: {
          XCTAssertEqual($0.status, .unauthorized, "\(method) /\(path)")
          XCTAssertNotNil($0.headers.first(name: "WWW-Authenticate"))
          XCTAssertFalse($0.body.string.contains(self.password))
        })
      }
    }
  }

  func testPasswordIsVerifiedAndAuthorizedRequestsReachTheirHandlers() throws {
    let app = Application(.testing); defer { app.shutdown() }
    registerRoutes(in: app, adminPassword: password)
    for (method, path) in protectedRoutes {
      try app.test(method, path, beforeRequest: {
        $0.headers.replaceOrAdd(name: .authorization, value: self.basic(self.password))
        $0.headers.contentType = .json
        $0.body = .init(string: "{}")
      }, afterResponse: {
        // Missing payload/query is rejected by the real handler, after the password check.
        XCTAssertEqual($0.status, path == "admin-session" ? .ok : .badRequest, "\(method) /\(path)")
        if path == "admin-session" {
          XCTAssertEqual($0.headers.first(name: .cacheControl), "no-store")
          XCTAssertEqual(try $0.content.decode(Session.self).authorized, true)
        }
      })
    }
  }

  func testUnconfiguredOrBlankPasswordFailsClosedForEveryAdministrativeRoute() throws {
    for config in [nil, "", " \n "] as [String?] {
      let app = Application(.testing); defer { app.shutdown() }
      registerRoutes(in: app, adminPassword: config)
      for (method, path) in protectedRoutes {
        try app.test(method, path, beforeRequest: {
          $0.headers.replaceOrAdd(name: .authorization, value: self.basic(self.password))
        }, afterResponse: { XCTAssertEqual($0.status, .serviceUnavailable, "\(method) /\(path)") })
      }
    }
  }

  func testPublicCalendarReadsAndTelegramSubscriptionRoutesRemainOutsideAdminGate() throws {
    let app = Application(.testing); defer { app.shutdown() }
    registerRoutes(in: app, adminPassword: nil)
    for (method, path) in [(HTTPMethod.GET, "race"), (.GET, "events"),
      (.POST, "subscribe"), (.DELETE, "subscribe")] {
      try app.test(method, path, beforeRequest: {
        $0.headers.contentType = .json
        $0.body = .init(string: "{}")
      }, afterResponse: {
        XCTAssertEqual($0.status, .badRequest, "Public handler should validate input for \(method) /\(path)")
      })
    }
  }

  private struct Session: Content { let authorized: Bool }
  private func basic(_ password: String, username: String = "admin") -> String {
    "Basic " + Data("\(username):\(password)".utf8).base64EncodedString()
  }
}
