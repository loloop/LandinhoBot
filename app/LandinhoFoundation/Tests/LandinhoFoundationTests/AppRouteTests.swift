import XCTest
@testable import LandinhoFoundation

final class AppRouteTests: XCTestCase {
  private let id = UUID(uuidString: "4CAEBFB4-C669-46F1-B74E-AD391517F373")!

  func testEveryDestinationRoundTripsThroughBothURLForms() throws {
    for route in [AppRoute.home, .categories, .settings, .category(tag: "f1"),
      .category(tag: "stock-car"), .category(tag: "fórmula_2"), .round(id: id)] {
      XCTAssertEqual(AppRoute(url: try XCTUnwrap(route.url)), route)
      XCTAssertEqual(AppRoute(url: try XCTUnwrap(route.canonicalURL)), route)
    }
    XCTAssertEqual(AppRoute.round(id: id).url?.absoluteString,
      "vroomvroom://rounds/4caebfb4-c669-46f1-b74e-ad391517f373")
    XCTAssertEqual(AppRoute.category(tag: "fórmula_2").url?.absoluteString,
      "vroomvroom://categories/f%C3%B3rmula_2")
  }

  func testRejectsWrongSchemesHostsCredentialsPortsAndExtraComponents() throws {
    let paths = [
      "http://vroomvroom.racing/home", "https://evil.example/home",
      "https://vroomvroom.racing.evil.example/home", "https://www.vroomvroom.racing/home",
      "https://user@vroomvroom.racing/home", "https://vroomvroom.racing:443/home",
      "https://vroomvroom.racing/home?redirect=https://evil.example", "vroomvroom://home#settings",
      "file:///home", "other://home", "vroomvroom:home", "vroomvroom:///home",
      "vroomvroom://unknown", "vroomvroom://home/extra", "vroomvroom://home/",
      "https://vroomvroom.racing//home", "https://vroomvroom.racing/",
      "vroomvroom://rounds/\(id)/extra", "vroomvroom://categories/f1/extra"
    ]
    for path in paths { XCTAssertNil(AppRoute(url: try XCTUnwrap(URL(string: path))), path) }
  }

  func testRejectsMalformedIDsAndUnsafeOrDoubleEncodedCategoryTags() throws {
    for value in ["", "bad-id", "4caebfb4c66946f1b74ead391517f373", "\(id)%2F",
      "00000000-0000-0000-0000-00000000000Z"] {
      XCTAssertNil(AppRoute(url: try XCTUnwrap(URL(string: "vroomvroom://rounds/" + value))))
    }
    for value in ["", "%2F", "%252F", "..", "%2e%2e", "%00", "%0A", "f1%20", "%GG", String(repeating: "a", count: 65)] {
      XCTAssertNil(AppRoute(url: try XCTUnwrap(URL(string: "vroomvroom://categories/" + value))), value)
    }
    for tag in ["", "a/b", "..", "f1\n", String(repeating: "a", count: 65)] {
      XCTAssertNil(AppRoute.category(tag: tag).url)
      XCTAssertNil(AppRoute.category(tag: tag).canonicalURL)
    }
    XCTAssertEqual(AppRoute(url: try XCTUnwrap(URL(string: "vroomvroom://categories/%66%31"))), .category(tag: "f1"))
  }

  func testRoundShareKeepsAppLinkAndUsesOnlyGenericCalendarioF1Fallback() throws {
    let f1 = Race(id: id, title: "São Paulo Grand Prix", shortTitle: "São Paulo", events: [],
      category: RaceCategory(id: "f1", title: "Formula 1", tag: "f1"))
    XCTAssertEqual(f1.roundLinkFallbackURL?.absoluteString, "https://calendariof1.com/")
    XCTAssertTrue(f1.roundLinkShareText.contains(try XCTUnwrap(AppRoute.round(id: id).url).absoluteString))
    XCTAssertTrue(f1.roundLinkShareText.contains("F1 na web (Calendário F1): https://calendariof1.com/"))
    XCTAssertFalse(f1.roundLinkShareText.contains(AppRoute.canonicalHost))
    let other = Race(id: id, title: "Stock Car", shortTitle: "Interlagos", events: [],
      category: RaceCategory(id: "stock-car", title: "Stock Car", tag: "stock-car"))
    XCTAssertNil(other.roundLinkFallbackURL)
    XCTAssertFalse(other.roundLinkShareText.contains("calendariof1.com"))
  }
}
