import Foundation
import XCTest
import LandinhoFoundation
@testable import AppClipFeature

final class ClipNavigationTests: XCTestCase {
  func testColdInvocationUsesSharedRoutes() throws {
    let roundID = UUID(uuidString: "c85e05f6-3c12-4a83-9c52-30d6adbb0012")!
    for route in [AppRoute.home, .categories, .category(tag: "f1"), .round(id: roundID)] {
      var navigation = ClipNavigation()
      navigation.receiveInvocation(try XCTUnwrap(route.canonicalURL))
      XCTAssertEqual(navigation.destination, route)
      XCTAssertEqual(navigation.fullAppRoute, route)
      XCTAssertNil(navigation.notice)
    }
  }

  func testWarmInvocationReplacesDestinationAndRefreshesRepeatedRoute() throws {
    var navigation = ClipNavigation()
    navigation.receiveInvocation(try XCTUnwrap(AppRoute.category(tag: "f1").canonicalURL))
    navigation.receiveInvocation(try XCTUnwrap(AppRoute.categories.canonicalURL))
    XCTAssertEqual(navigation.destination, .categories)
    let revision = navigation.revision
    navigation.receiveInvocation(try XCTUnwrap(AppRoute.categories.canonicalURL))
    XCTAssertGreaterThan(navigation.revision, revision)
  }

  func testNoURLRestoresPreviousDestinationAndPreservesWarmDestination() throws {
    let route = AppRoute.round(id: UUID())
    var navigation = ClipNavigation(restoredURL: try XCTUnwrap(route.url))
    let previous = navigation
    navigation.receiveInvocation(nil)
    XCTAssertEqual(navigation, previous)
    XCTAssertEqual(navigation.destination, route)
    XCTAssertEqual(ClipNavigation(restoredURL: URL(string: "https://evil.example/home")).destination, .home)
    XCTAssertEqual(ClipNavigation().destination, .home)
  }

  func testInvalidInvocationsClearPreviousContextWithoutAcceptingRedirects() throws {
    for value in ["https://evil.example/categories/f1", "https://vroomvroom.racing.evil.example/home",
      "http://vroomvroom.racing/home", "vroomvroom://home", "https://vroomvroom.racing/home?redirect=evil",
      "https://vroomvroom.racing/rounds/not-a-uuid", "https://vroomvroom.racing/categories/../settings"] {
      var navigation = ClipNavigation(restoredURL: try XCTUnwrap(AppRoute.category(tag: "f1").url))
      navigation.receiveInvocation(try XCTUnwrap(URL(string: value)))
      XCTAssertEqual(navigation.destination, .home, value)
      XCTAssertEqual(navigation.fullAppRoute, .home, value)
      XCTAssertNotNil(navigation.notice, value)
    }
  }

  func testSettingsOffersEquivalentFullAppHandoffWithoutAdminInClip() throws {
    var navigation = ClipNavigation()
    navigation.receiveInvocation(try XCTUnwrap(AppRoute.settings.canonicalURL))
    XCTAssertEqual(navigation.destination, .home)
    XCTAssertEqual(navigation.fullAppRoute.url?.absoluteString, "vroomvroom://settings")
    XCTAssertNotNil(navigation.notice)
    navigation.navigate(to: .categories)
    XCTAssertNil(navigation.notice)
    XCTAssertEqual(navigation.fullAppRoute, .categories)
  }
}
