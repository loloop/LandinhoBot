import XCTest
import ComposableArchitecture
import LandinhoFoundation
@testable import Router

@MainActor
final class RouterTests: XCTestCase {
  func testRoundLinkReplacesNavigationAndRepeatedLinkIsIdempotent() async {
    let id = UUID()
    let store = TestStore(initialState: Router.State()) { Router() }
    await store.send(.openRoute(.category(tag: "f1"))) {
      $0.selectedTab = .categories
      $0.lastOpenedRoute = .category(tag: "f1")
      $0.path.append(.scheduleList(.init(categoryTag: "f1")))
    }
    await store.send(.openRoute(.round(id: id))) {
      $0.selectedTab = .home
      $0.lastOpenedRoute = .round(id: id)
      $0.path.removeAll()
      $0.path.append(.eventDetail(.init(raceID: id)))
    }
    await store.send(.openRoute(.round(id: id)))
    XCTAssertEqual(store.state.path.count, 1)
  }

  func testHomeCategoriesAndSettingsSelectTabsAndClearDetailNavigation() async {
    for (route, tab) in [(AppRoute.home, Router.Tab.home), (.categories, .categories), (.settings, .settings)] {
      let store = TestStore(initialState: Router.State()) { Router() }
      let id = UUID()
      await store.send(.openRoute(.round(id: id))) {
        $0.lastOpenedRoute = .round(id: id)
        $0.path.append(.eventDetail(.init(raceID: id)))
      }
      await store.send(.openRoute(route)) {
        $0.selectedTab = tab
        $0.lastOpenedRoute = route
        $0.path.removeAll()
      }
      XCTAssertTrue(store.state.path.isEmpty)
      XCTAssertEqual(store.state.selectedTab, tab)
    }
  }

  func testInvalidProgrammaticCategoryRouteIsIgnored() async {
    let store = TestStore(initialState: Router.State()) { Router() }
    await store.send(.openRoute(.category(tag: "../settings")))
    XCTAssertTrue(store.state.path.isEmpty)
  }

  func testOpeningSavedHomeRoundPreservesItsFreshnessForDetailRevalidation() async {
    let race = Race(id: UUID(), title: "São Paulo", shortTitle: "SP", events: [],
      category: RaceCategory(id: "f1", title: "Formula 1", tag: "f1"))
    let savedAt = Date(timeIntervalSince1970: 1_800_000_000)
    let store = TestStore(initialState: Router.State()) { Router() }
    await store.send(.home(.scheduleList(.delegate(.onWidgetTap(race, savedAt: savedAt))))) {
      $0.path.append(.eventDetail(.init(race: race, savedAt: savedAt)))
    }
  }
}
