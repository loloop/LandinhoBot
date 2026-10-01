import XCTest
@testable import LandinhoFoundation

final class HomeScreenQuickActionTests: XCTestCase {
  func testDeclaredActionsUseExistingAppRoutes() throws {
    let appDirectory = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
    let plist = try PropertyListSerialization.propertyList(
      from: Data(contentsOf: appDirectory.appendingPathComponent("VroomVroom/Info.plist")),
      format: nil) as! [String: Any]
    let items = try XCTUnwrap(plist["UIApplicationShortcutItems"] as? [[String: Any]])
    let types = try items.map { try XCTUnwrap($0["UIApplicationShortcutItemType"] as? String) }
    XCTAssertEqual(types.count, HomeScreenQuickAction.allCases.count)
    XCTAssertEqual(Set(types), Set(HomeScreenQuickAction.allCases.map(\.rawValue)))

    let expectedRoutes: [AppRoute] = [.home, .categories, .settings]
    for (type, route) in zip(types, expectedRoutes) {
      let action = try XCTUnwrap(HomeScreenQuickAction(rawValue: type))
      XCTAssertEqual(action.route, route)
      XCTAssertEqual(AppRoute(url: try XCTUnwrap(action.route.url)), route)
    }
  }

  func testUnknownAndModifiedActionTypesAreRejected() {
    let validType = HomeScreenQuickAction.settings.rawValue
    for type in ["", "settings", "vroomvroom://settings", validType.uppercased(),
      validType + ".extra", " " + validType,
      "me.mauriciocardozo.racing.vroomvroom.quick-action.rounds"] {
      XCTAssertNil(HomeScreenQuickAction(rawValue: type), type)
    }
  }
}
