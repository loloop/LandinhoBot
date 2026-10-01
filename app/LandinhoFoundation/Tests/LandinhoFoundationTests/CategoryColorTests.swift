import XCTest
@testable import LandinhoFoundation

final class CategoryColorTests: XCTestCase {
  func testLegacyMissingNullAndInvalidColorsUseStableFallback() throws {
    for field in ["", #", "color": null"#, #", "color": "red""#, #", "color": 42"#] {
      let data = Data(##"{"id":"legacy","title":"Formula 1","tag":"f1"\##(field)}"##.utf8)
      let category = try JSONDecoder().decode(RaceCategory.self, from: data)
      XCTAssertNil(category.color)
      XCTAssertEqual(category.resolvedColor.hex, "#A77625")
    }
    XCTAssertEqual(CategoryColor.fallback(for: "F1"), CategoryColor.fallback(for: "f1"))
    XCTAssertEqual(CategoryColor.fallback(for: "stock-car").hex, "#4A6FA5")
  }

  func testColorRoundTripNormalizesHexAndPreservesRGBComponents() throws {
    let data = Data(##"{"id":"f1","title":"Formula 1","tag":"f1","color":"#a1b2c3"}"##.utf8)
    let category = try JSONDecoder().decode(RaceCategory.self, from: data)
    XCTAssertEqual(category.color?.hex, "#A1B2C3")
    XCTAssertEqual(category.resolvedColor.red, 161.0 / 255)
    XCTAssertEqual(category.resolvedColor.green, 178.0 / 255)
    XCTAssertEqual(category.resolvedColor.blue, 195.0 / 255)
    let encoded = try JSONEncoder().encode(category)
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    XCTAssertEqual(object["color"] as? String, "#A1B2C3")
    XCTAssertEqual(try JSONDecoder().decode(RaceCategory.self, from: encoded), category)
  }

  func testAutomaticColorEncodesExplicitNullForEditorReset() throws {
    let category = RaceCategory(id: "f1", title: "Formula 1", tag: "f1")
    let object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(category)) as? [String: Any])
    XCTAssertTrue(object["color"] is NSNull)
  }

  func testOnlyOpaqueSixDigitHexIsAccepted() throws {
    for invalid in ["red", "#FFF", "#11223344", "112233", "#GG2233", " #112233", "#１２３４５６"] {
      XCTAssertNil(CategoryColor(hex: invalid), invalid)
      XCTAssertThrowsError(try JSONDecoder().decode(CategoryColor.self, from: JSONEncoder().encode(invalid)))
    }
    XCTAssertEqual(CategoryColor(red: 0, green: 255, blue: 16).hex, "#00FF10")
  }
}
