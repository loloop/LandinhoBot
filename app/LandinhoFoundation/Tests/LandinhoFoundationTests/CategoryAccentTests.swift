import XCTest
@testable import LandinhoFoundation

final class CategoryAccentTests: XCTestCase {
  func testContrastMatchesKnownSRGBReferenceValues() {
    let white = color("#FFFFFF")
    let black = color("#000000")
    XCTAssertEqual(white.contrastRatio(with: black), 21, accuracy: 0.0001)
    XCTAssertEqual(black.contrastRatio(with: white), 21, accuracy: 0.0001)
    XCTAssertEqual(white.contrastRatio(with: white), 1)
    // This commonly borderline gray must not be rounded up to 4.5.
    XCTAssertEqual(color("#777777").contrastRatio(with: white), 4.478, accuracy: 0.001)
  }

  func testChallengingColorsReachMinimumContrastOnAppSurfaces() {
    let surfaces = ["#FFFFFF", "#F2F2F7", "#000000", "#1C1C1E", "#2C2C2E", "#777777"]
    let identities = ["#FFFFFF", "#000000", "#FFFF00", "#00FF00", "#00FFFF", "#FF00FF", "#E34B43", "#777777"]
    for surface in surfaces {
      for identity in identities {
        let background = color(surface)
        let original = color(identity)
        let accent = original.readableAccent(on: background)
        XCTAssertGreaterThanOrEqual(accent.contrastRatio(with: background), 4.5, "\(identity) on \(surface)")
        XCTAssertEqual(accent.readableAccent(on: background), accent)
        if original.contrastRatio(with: background) >= 4.5 {
          XCTAssertEqual(accent, original, "Readable colors keep their identity")
        }
      }
    }
  }

  func testYellowRetainsItsHueWhenDarkenedAndStoredIdentityIsUnchanged() {
    let yellow = color("#FFFF00")
    let accent = yellow.readableAccent(on: color("#F2F2F7"))
    XCTAssertEqual(accent.red, accent.green)
    XCTAssertEqual(accent.blue, 0)
    XCTAssertLessThan(accent.red, yellow.red)
    XCTAssertEqual(yellow.hex, "#FFFF00")
    XCTAssertEqual(color("#006699").readableAccent(on: color("#FFFFFF")), color("#006699"))
  }

  private func color(_ hex: String) -> CategoryColor {
    CategoryColor(hex: hex)!
  }
}
