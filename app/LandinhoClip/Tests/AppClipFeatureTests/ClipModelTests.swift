import Foundation
import XCTest
import LandinhoFoundation
@testable import AppClipFeature

@MainActor
final class ClipModelTests: XCTestCase {
  private func defaults() -> UserDefaults {
    let suite = "ClipModelTests." + UUID().uuidString
    return UserDefaults(suiteName: suite)!
  }

  func testNoURLLaunchRestoresRoundAndIgnoresUnrelatedActivities() throws {
    let defaults = defaults()
    let model = ClipModel(defaults: defaults)
    let route = AppRoute.round(id: UUID())
    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    activity.webpageURL = try XCTUnwrap(route.canonicalURL)
    model.receive(activity)
    let restored = ClipModel(defaults: defaults)
    restored.receive(NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb))
    XCTAssertEqual(restored.navigation.destination, route)
    let unrelated = NSUserActivity(activityType: "unrelated")
    unrelated.webpageURL = AppRoute.settings.canonicalURL
    restored.receive(unrelated)
    XCTAssertEqual(restored.navigation.destination, route)
  }

  func testLatePreviousRequestCannotReplaceWarmInvocationContent() async throws {
    let started = expectation(description: "Previous request started")
    var delayed: CheckedContinuation<(Data, URLResponse), Error>?
    let client = ClipCalendarClient { request in
      if request.url?.path == "/next-races" {
        return try await withCheckedThrowingContinuation { continuation in
          delayed = continuation
          started.fulfill()
        }
      }
      return (Data("[]".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let model = ClipModel(client: client, defaults: defaults())
    let previous = Task { await model.reload() }
    await fulfillment(of: [started], timeout: 2)
    let activity = NSUserActivity(activityType: NSUserActivityTypeBrowsingWeb)
    activity.webpageURL = AppRoute.categories.canonicalURL
    model.receive(activity)
    await model.reload()
    XCTAssertEqual(model.content, .categories([]))
    let url = URL(string: "https://api.vroomvroom.racing/next-races")!
    delayed?.resume(returning: (Data("{\"items\":[]}".utf8), HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!))
    await previous.value
    XCTAssertEqual(model.content, .categories([]))
  }

  func testUnavailableRoundShowsRecoveryAndRetryCanSucceed() async throws {
    var fail = true
    let client = ClipCalendarClient { request in
      (Data(ClipCalendarClientTests.roundJSON.utf8),
        HTTPURLResponse(url: request.url!, statusCode: fail ? 404 : 200, httpVersion: nil, headerFields: nil)!)
    }
    let model = ClipModel(client: client, defaults: defaults())
    model.navigate(to: .round(id: ClipCalendarClientTests.id))
    await model.reload()
    guard case .failure(let message) = model.content else { return XCTFail("Expected recovery state") }
    XCTAssertTrue(message.contains("Esta etapa não está disponível"))
    fail = false
    await model.reload()
    guard case .round(let round) = model.content else { return XCTFail("Expected round after retry") }
    XCTAssertEqual(round.id, ClipCalendarClientTests.id)
  }

  func testOlderReloadCannotOverwriteLatestReloadAtSameDestination() async throws {
    let started = expectation(description: "First reload started")
    var delayed: CheckedContinuation<(Data, URLResponse), Error>?
    var count = 0
    let client = ClipCalendarClient { request in
      count += 1
      if count == 1 {
        return try await withCheckedThrowingContinuation { continuation in
          delayed = continuation
          started.fulfill()
        }
      }
      return (Data("{\"items\":[]}".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let model = ClipModel(client: client, defaults: defaults())
    let first = Task { await model.reload() }
    await fulfillment(of: [started], timeout: 2)
    await model.reload()
    XCTAssertEqual(model.content, .rounds([]))
    let url = URL(string: "https://api.vroomvroom.racing/next-races")!
    delayed?.resume(returning: (Data(), HTTPURLResponse(url: url, statusCode: 503, httpVersion: nil, headerFields: nil)!))
    await first.value
    XCTAssertEqual(model.content, .rounds([]))
  }

  func testFullAppHandoffPreservesDestinationAndHandlesUnavailableApp() {
    let model = ClipModel(defaults: defaults())
    let round = AppRoute.round(id: ClipCalendarClientTests.id)
    model.navigate(to: round)
    model.openFullApp { url, completion in
      XCTAssertEqual(url, round.url)
      completion(false)
    }
    XCTAssertTrue(model.isAppUnavailable)
    model.navigate(to: .settings)
    model.openFullApp { url, completion in
      XCTAssertEqual(url, AppRoute.settings.url)
      completion(true)
    }
    XCTAssertFalse(model.isAppUnavailable)
  }
}
