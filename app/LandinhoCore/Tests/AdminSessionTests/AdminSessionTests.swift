import AdminSession
import XCTest

final class AdminSessionTests: XCTestCase {
  func testOnlyVerifiedPasswordCanBeUsedAndOnlyForAdministration() {
    let session = AdminSession()
    XCTAssertNil(session.header(endpoint: "import-settings", method: "GET"))
    let attempt = session.beginUnlock()
    XCTAssertNil(session.header(endpoint: "import-settings", method: "GET"))
    XCTAssertTrue(session.completeUnlock(password: "test:ç", attempt: attempt))
    let expected = AdminSession.header(password: "test:ç")
    for endpoint in ["admin-session", "prune-race", "imports", "import-settings", "import-refresh", "import-match"] {
      XCTAssertEqual(session.header(endpoint: endpoint, method: "GET"), expected)
    }
    for endpoint in ["category", "race", "events"] {
      XCTAssertNil(session.header(endpoint: endpoint, method: "GET"))
      XCTAssertEqual(session.header(endpoint: endpoint, method: "POST"), expected)
      XCTAssertEqual(session.header(endpoint: endpoint, method: "PATCH"), expected)
    }
    for endpoint in ["next-race", "next-races", "subscribe", "subscriptions/123", "upcoming-alerts"] {
      XCTAssertNil(session.header(endpoint: endpoint, method: "POST"))
    }
  }

  func testLockRemovesCredentialAndRejectsLateUnlockCompletion() {
    let session = AdminSession()
    let attempt = session.beginUnlock()
    XCTAssertTrue(session.completeUnlock(password: "test", attempt: attempt))
    session.lock()
    XCTAssertNil(session.header(endpoint: "category", method: "POST"))
    XCTAssertFalse(session.completeUnlock(password: "test", attempt: attempt))
    XCTAssertNil(session.header(endpoint: "import-settings", method: "GET"))
  }

  func testRetryInvalidatesPreviousAttemptAndAcceptsNewVerification() {
    let session = AdminSession()
    let first = session.beginUnlock()
    let retry = session.beginUnlock()
    XCTAssertFalse(session.completeUnlock(password: "first", attempt: first))
    XCTAssertTrue(session.completeUnlock(password: "retry", attempt: retry))
    XCTAssertEqual(session.header(endpoint: "imports", method: "GET"), AdminSession.header(password: "retry"))
  }
}
