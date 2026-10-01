import XCTest
import ComposableArchitecture
@_spi(Internal) import APIClient
import LandinhoFoundation
@testable import EventDetail

@MainActor
final class EventDetailTests: XCTestCase {
  func testFetchByIDUsesPublicEndpointAndRepeatedAppearanceDoesNotRestart() async {
    let race = makeRace()
    let recorder = RequestRecorder()
    let store = TestStore(initialState: EventDetail.State(raceID: race.id)) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { endpoint in
      await recorder.record(endpoint)
      return race
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.send(.onAppear)
    await store.receive(.response(.success(race))) {
      $0.isLoading = false
      $0.race = race
    }
    await store.send(.onAppear)
    let endpoints = await recorder.endpoints
    XCTAssertEqual(endpoints, ["rounds/" + race.id.uuidString.lowercased()])
  }

  func testNotFoundShowsRecoverableFailureAndRetryLoadsRound() async {
    let race = makeRace()
    let recorder = RequestRecorder()
    let failure = NSError(domain: "LandinhoAPI", code: 404)
    let store = TestStore(initialState: EventDetail.State(raceID: race.id)) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { endpoint in
      let attempt = await recorder.record(endpoint)
      if attempt == 1 { throw failure }
      return race
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.receive(.response(.failure(failure))) {
      $0.isLoading = false
      $0.loadFailure = .notFound
    }
    await store.send(.onAppear)
    await store.send(.retry) {
      $0.isLoading = true
      $0.loadFailure = nil
    }
    await store.receive(.response(.success(race))) {
      $0.isLoading = false
      $0.race = race
    }
  }

  func testLeavingCancelsRequestWithoutPresentingAnError() async {
    let race = makeRace()
    let store = TestStore(initialState: EventDetail.State(raceID: UUID())) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { _ in
      try await Task.sleep(nanoseconds: 30_000_000_000)
      return race
    }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.send(.onDisappear) { $0.isLoading = false }
    await store.finish()
    XCTAssertNil(store.state.loadFailure)
  }

  func testWrongRoundIDCannotShowAnUnrelatedRound() async {
    let race = makeRace()
    let store = TestStore(initialState: EventDetail.State(raceID: UUID())) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { _ in race }
    await store.send(.onAppear) { $0.isLoading = true }
    await store.receive(.response(.success(race))) {
      $0.isLoading = false
      $0.loadFailure = .unavailable
    }
    XCTAssertNil(store.state.race)
  }

  func testPreloadedRoundNeverFetches() async {
    let race = makeRace()
    let store = TestStore(initialState: EventDetail.State(race: race)) { EventDetail() }
    store.dependencies.apiRequester = RoundRequester { _ in
      XCTFail("A preloaded round should not request the API")
      return race
    }
    await store.send(.onAppear)
    await store.finish()
  }

  private func makeRace() -> Race {
    Race(id: UUID(), title: "São Paulo Grand Prix", shortTitle: "São Paulo", events: [],
      category: RaceCategory(id: "f1", title: "Formula 1", tag: "f1"))
  }
}

private actor RequestRecorder {
  var endpoints: [String] = []
  @discardableResult func record(_ endpoint: String) -> Int {
    endpoints.append(endpoint)
    return endpoints.count
  }
}

private struct RoundRequester: APIClientServiceProtocol {
  static let liveValue = Self { _ in throw URLError(.unsupportedURL) }
  let load: (String) async throws -> Race
  init(_ load: @escaping (String) async throws -> Race) { self.load = load }
  func request<T: Decodable>(_: T.Type, endpoint: String, method: String, data: Data?,
    queryItems: [URLQueryItem], headers: [String: String]) async throws -> T {
    XCTAssertEqual(method, "GET")
    XCTAssertNil(data)
    XCTAssertTrue(queryItems.isEmpty)
    XCTAssertTrue(headers.isEmpty)
    guard let response = try await load(endpoint) as? T else { throw URLError(.cannotParseResponse) }
    return response
  }
  func setPersistentHeaders(_ headers: [String: String]) {}
}
