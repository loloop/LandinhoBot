import Foundation
import XCTest
@testable import LandinhoFoundation

final class AppSharingTests: XCTestCase {
  func testBetaSharesWorkingProjectAndLabelsInstalledAppRequirement() {
    let sharing = AppSharing()
    XCTAssertNil(sharing.appClipURL)
    XCTAssertNil(sharing.appStoreURL)
    XCTAssertTrue(sharing.shareText.contains("Abrir o app instalado: vroomvroom://home"))
    XCTAssertTrue(sharing.shareText.contains(AppSharing.projectURL.absoluteString))
    XCTAssertFalse(sharing.shareText.contains(AppRoute.canonicalHost))
  }

  func testActivatedClipTakesPriorityOverAppStore() {
    let sharing = AppSharing(appClipURL: "https://vroomvroom.racing/categories/f1",
      appStoreURL: "https://apps.apple.com/br/app/vroomvroom/id123456789")
    XCTAssertEqual(sharing.shareText.components(separatedBy: "\n").last,
      "https://vroomvroom.racing/categories/f1")
    XCTAssertFalse(sharing.shareText.contains(AppSharing.projectURL.absoluteString))
  }

  func testInvalidDistributionConfigurationFallsBackToProject() {
    for value in ["", "http://vroomvroom.racing/home", "https://evil.example/home",
      "vroomvroom://home", "https://vroomvroom.racing/home?redirect=evil", "https://vroomvroom.racing/"] {
      XCTAssertNil(AppSharing(appClipURL: value).appClipURL, value)
    }
    for value in ["https://apps.apple.com.evil.example/id123", "http://apps.apple.com/id123",
      "https://user@apps.apple.com/id123", "https://apps.apple.com/id", "https://apps.apple.com/idabc",
      "https://apps.apple.com/id123?redirect=evil"] {
      XCTAssertNil(AppSharing(appStoreURL: value).appStoreURL, value)
    }
    let sharing = AppSharing(appClipURL: "https://evil.example/home",
      appStoreURL: "https://apps.apple.com/br/app/vroomvroom/id123456789")
    XCTAssertTrue(sharing.shareText.contains("apps.apple.com"))
    XCTAssertFalse(sharing.shareText.contains("evil.example"))
  }
}
