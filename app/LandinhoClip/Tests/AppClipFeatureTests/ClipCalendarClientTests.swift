import Foundation
import XCTest
import LandinhoFoundation
@testable import AppClipFeature

final class ClipCalendarClientTests: XCTestCase {
  static let id = UUID(uuidString: "c85e05f6-3c12-4a83-9c52-30d6adbb0012")!
  static let roundJSON = """
  {"id":"c85e05f6-3c12-4a83-9c52-30d6adbb0012","title":"São Paulo","shortTitle":"São Paulo","category":{"id":"f1","title":"Formula 1","tag":"f1"},"events":[{"id":"013340b8-ecce-4c38-a379-5414a1337088","title":"Classificação","date":"2026-11-07T18:00:00Z","isMainEvent":false},{"id":"3b0c9833-1470-44c9-aeff-360718004828","title":"Corrida","date":null,"scheduledDay":"2026-11-08","isMainEvent":true}]}
  """

  func testPublicRoundRequestDecodesConfirmedAndPendingSessions() async throws {
    let client = ClipCalendarClient { request in
      XCTAssertEqual(request.url?.host, "api.vroomvroom.racing")
      XCTAssertEqual(request.url?.path, "/rounds/" + Self.id.uuidString.lowercased())
      XCTAssertEqual(request.httpMethod, "GET")
      XCTAssertNil(request.httpBody)
      XCTAssertNil(request.value(forHTTPHeaderField: "Authorization"))
      return (Data(Self.roundJSON.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let round = try await client.round(id: Self.id)
    XCTAssertNotNil(round.events[0].date)
    XCTAssertEqual(round.events[1].timeLabel, "Horário pendente")
    XCTAssertEqual(round.events[1].dayLabel, "08/11")
  }

  func testCategoryPreviewUsesExistingPaginationContractAndExcludesCancelledRounds() async throws {
    let client = ClipCalendarClient(baseURL: URL(string: "http://127.0.0.1:8080/api")!) { request in
      XCTAssertEqual(request.url?.path, "/api/next-races")
      let query = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!.queryItems!
      XCTAssertEqual(query, [.init(name: "page", value: "1"), .init(name: "per", value: "5"), .init(name: "category", value: "f1")])
      let cancelled = Self.roundJSON.dropLast() + ",\"isCancelled\":true}"
      return (Data("{\"items\":[\(Self.roundJSON),\(cancelled)]}".utf8),
        HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    let rounds = try await client.rounds(category: "f1")
    XCTAssertEqual(rounds.count, 1)
  }

  func testMissingRoundAndInvalidPayloadAreFailures() async throws {
    let missing = ClipCalendarClient { request in
      (Data(), HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!)
    }
    do { _ = try await missing.round(id: Self.id); XCTFail("Expected unavailable round") }
    catch { XCTAssertEqual((error as NSError).code, 404) }
    let invalid = ClipCalendarClient { request in
      (Data("not-json".utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    do { _ = try await invalid.categories(); XCTFail("Expected decoding error") }
    catch { XCTAssertTrue(error is DecodingError) }
  }

  func testUnrelatedRoundFromServerCannotReplaceRequestedRound() async throws {
    let client = ClipCalendarClient { request in
      (Data(Self.roundJSON.utf8), HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!)
    }
    do { _ = try await client.round(id: UUID()); XCTFail("Expected ID mismatch failure") }
    catch { XCTAssertEqual((error as? URLError)?.code, .cannotDecodeContentData) }
  }
}
