@testable import App
import Fluent
import SQLKit
import XCTVapor

final class CategoryColorTests: XCTestCase {
  private let adminPassword = "category-color-test-only"
  private struct PublicCategory: Content {
    let id: UUID
    let color: String?
  }

  func testValidatesAndNormalizesOnlyOpaqueSixDigitHex() throws {
    XCTAssertNil(try validatedCategoryColor(nil))
    XCTAssertEqual(try validatedCategoryColor("#a1b2c3"), "#A1B2C3")
    for invalid in ["red", "#FFF", "#11223344", "112233", "#GG2233", " #112233", "#１２３４５６"] {
      XCTAssertThrowsError(try validatedCategoryColor(invalid)) { error in
        XCTAssertEqual((error as? AbortError)?.status, .badRequest)
      }
    }
  }

  func testLegacyCreateAndPatchDistinguishMissingFromExplicitNull() throws {
    let upload = try JSONDecoder().decode(UploadCategoryHandler.UploadCategoryRequest.self,
      from: Data(##"{"title":"Legacy","categoryTag":"legacy"}"##.utf8))
    XCTAssertNil(upload.color)
    let prefix = #"{"id":"00000000-0000-0000-0000-000000000001","title":"Legacy","tag":"legacy""#
    let missing = try JSONDecoder().decode(UpdateCategoryHandler.UpdateCategoryRequest.self, from: Data((prefix + "}").utf8))
    let cleared = try JSONDecoder().decode(UpdateCategoryHandler.UpdateCategoryRequest.self, from: Data((prefix + #", "color": null}"#).utf8))
    XCTAssertFalse(missing.updatesColor)
    XCTAssertNil(missing.color)
    XCTAssertTrue(cleared.updatesColor)
    XCTAssertNil(cleared.color)
  }

  func testInvalidColorsReturnBadRequestBeforeDatabaseAccess() throws {
    let app = Application(.testing)
    defer { app.shutdown() }
    [UploadCategoryHandler(), UpdateCategoryHandler()].register(in: app)
    for (method, json) in [
      (HTTPMethod.POST, ##"{"title":"Invalid","categoryTag":"invalid","color":"#FFF"}"##),
      (.PATCH, ##"{"id":"00000000-0000-0000-0000-000000000001","title":"Invalid","tag":"invalid","color":"red"}"##)
    ] {
      try app.test(method, "category", beforeRequest: {
        $0.headers.contentType = .json
        $0.body = ByteBuffer(string: json)
      }, afterResponse: { XCTAssertEqual($0.status, .badRequest) })
    }
  }

  func testCreateEditLegacyPatchAndResetPersistColor() async throws {
    let app = try await makeApp()
    defer { app.shutdown() }
    let tag = "color-" + UUID().uuidString
    let title = "Color " + UUID().uuidString
    var id: UUID?
    try app.test(.POST, "category", beforeRequest: {
      $0.headers.basicAuthorization = .init(username: "admin", password: self.adminPassword)
      $0.headers.contentType = .json
      $0.body = ByteBuffer(string: ##"{"title":"\##(title)","categoryTag":"\##(tag)","color":"#a1b2c3"}"##)
    }, afterResponse: {
      XCTAssertEqual($0.status, .ok)
      let saved = try $0.content.decode(PublicCategory.self)
      id = saved.id
      XCTAssertEqual(saved.color, "#A1B2C3")
    })
    let savedID = try XCTUnwrap(id)
    var persisted = try await App.Category.find(savedID, on: app.db)
    XCTAssertEqual(persisted?.color, "#A1B2C3")
    for (field, expected) in [
      (##", "color":"#123abc""##, "#123ABC" as String?),
      ("", "#123ABC"),
      (#", "color":null"#, nil)
    ] {
      try app.test(.PATCH, "category", beforeRequest: {
        $0.headers.basicAuthorization = .init(username: "admin", password: self.adminPassword)
        $0.headers.contentType = .json
        $0.body = ByteBuffer(string: ##"{"id":"\##(savedID)","title":"\##(title)","tag":"\##(tag)"\##(field)}"##)
      }, afterResponse: {
        XCTAssertEqual($0.status, .ok)
        XCTAssertEqual(try $0.content.decode(PublicCategory.self).color, expected)
      })
      persisted = try await App.Category.find(savedID, on: app.db)
      XCTAssertEqual(persisted?.color, expected)
    }
    try app.test(.GET, "category", afterResponse: {
      let category = try XCTUnwrap($0.content.decode([PublicCategory].self).first { $0.id == savedID })
      XCTAssertNil(category.color)
    })
    try await persisted?.delete(on: app.db)
  }

  func testMigrationRetainsLegacyCategoryAndRoundRelationship() async throws {
    let app = try await makeApp()
    defer { app.shutdown() }
    // This isolated database permits exercising just the new column's rollback and re-apply.
    let category = App.Category(title: "Migration " + UUID().uuidString, tag: UUID().uuidString, comment: "Preserve me")
    try await category.create(on: app.db)
    let round = Race(title: "Existing round", earliestEventDate: Date(), shortTitle: "Existing")
    round.$category.id = try category.requireID()
    try await round.create(on: app.db)
    let categoryID = try category.requireID()
    let roundID = try round.requireID()
    try await v0_4Migration().revert(on: app.db)
    try await v0_4Migration().prepare(on: app.db)
    let categoryResult = try await App.Category.find(categoryID, on: app.db)
    let roundResult = try await Race.find(roundID, on: app.db)
    let restored = try XCTUnwrap(categoryResult)
    let restoredRound = try XCTUnwrap(roundResult)
    XCTAssertEqual(restored.comment, "Preserve me")
    XCTAssertNil(restored.color)
    XCTAssertEqual(restoredRound.$category.id, categoryID)
    try await restoredRound.delete(on: app.db)
    try await restored.delete(on: app.db)
  }

  private func makeApp() async throws -> Application {
    guard Environment.get("LANDINHO_TEST_DATABASE") == "1" else {
      throw XCTSkip("Set LANDINHO_TEST_DATABASE=1 with a disposable PostgreSQL database")
    }
    let app = Application(.testing)
    do { try await configure(app, adminPassword: adminPassword); return app }
    catch { app.shutdown(); throw error }
  }
}
