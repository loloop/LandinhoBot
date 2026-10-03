@_spi(Internal) import APIClient
import CalendarStore
import ComposableArchitecture
import Foundation
import LandinhoFoundation
@testable import Categories
import XCTest

@MainActor
final class CategoriesTests: XCTestCase {
  private let date = Date(timeIntervalSince1970: 1_800_000_000)
  private let category = RaceCategory(id: "f1", title: "Formula 1", tag: "f1")

  func testSavedCategoriesStayVisibleDuringRefreshAndAfterNetworkFailure() async throws {
    let local = CalendarStore(databaseURL: nil)
    try await local.saveCategories([category], date)
    let saved = SavedCalendar(value: [category], updatedAt: date)
    let error = URLError(.notConnectedToInternet)
    let clock = TestClock()
    let requests = CategoryRequestCounter()
    let store = TestStore(initialState: Categories.State()) { Categories() } withDependencies: {
      $0.calendarStore = local
      $0.apiRequester = CategoryRequester {
        await requests.record()
        try await clock.sleep(for: .seconds(1))
        throw error
      }
    }
    store.exhaustivity = .off
    await store.send(.onAppear)
    await store.receive(.savedCategories(saved))
    await store.receive(.categoriesRequest(.refresh(.get)))
    XCTAssertEqual(store.state.categoriesState.response, .reloading([category]))
    await store.send(.onAppear)
    await store.send(.refresh)
    await clock.advance(by: .seconds(1))
    await store.receive(.categoriesRequest(.response(.finished(.failure(error)))))
    XCTAssertEqual(store.state.categoriesState.response.value, [category])
    XCTAssertNotNil(store.state.categoriesState.lastError)
    XCTAssertEqual(store.state.lastUpdatedDate, date)
    await store.finish()
    let count = await requests.count
    XCTAssertEqual(count, 1)
  }

  func testFreshCategoriesAreSavedAndEmptyServerResponseReplacesOldCategories() async throws {
    let local = CalendarStore(databaseURL: nil)
    try await local.saveCategories([category], date)
    let store = TestStore(initialState: Categories.State()) { Categories() } withDependencies: {
      $0.date.now = date.addingTimeInterval(60)
      $0.calendarStore = local
      $0.apiRequester = CategoryRequester { [] }
    }
    store.exhaustivity = .off
    await store.send(.onAppear)
    await store.receive(.categoriesRequest(.response(.finished(.success([])))))
    await store.finish()
    XCTAssertEqual(store.state.categoriesState.response.value, [])
    let saved = try await local.loadCategories()
    XCTAssertEqual(saved?.value, [])
    XCTAssertEqual(saved?.updatedAt, date.addingTimeInterval(60))
  }

  func testFirstLaunchOfflineStillShowsAnErrorWhenNothingHasBeenSaved() async {
    let error = URLError(.notConnectedToInternet)
    let store = TestStore(initialState: Categories.State()) { Categories() } withDependencies: {
      $0.apiRequester = CategoryRequester { throw error }
    }
    store.exhaustivity = .off
    await store.send(.onAppear)
    await store.receive(.categoriesRequest(.response(.finished(.failure(error)))))
    XCTAssertNil(store.state.categoriesState.response.value)
    XCTAssertEqual(store.state.categoriesState.response, .finished(.failure(error)))
    await store.finish()
  }
}

private actor CategoryRequestCounter {
  var count = 0
  func record() { count += 1 }
}

private struct CategoryRequester: APIClientServiceProtocol {
  static let liveValue = Self { throw URLError(.unsupportedURL) }
  let load: () async throws -> [RaceCategory]
  init(_ load: @escaping () async throws -> [RaceCategory]) { self.load = load }
  func request<T: Decodable>(_: T.Type, endpoint: String, method: String, data: Data?,
    queryItems: [URLQueryItem], headers: [String: String]) async throws -> T {
    XCTAssertEqual(endpoint, "category")
    XCTAssertEqual(method, "GET")
    guard let response = try await load() as? T else { throw URLError(.cannotParseResponse) }
    return response
  }
  func setPersistentHeaders(_ headers: [String: String]) {}
}
