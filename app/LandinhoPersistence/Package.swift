// swift-tools-version: 6.4
import PackageDescription

let package = Package(
  name: "LandinhoPersistence",
  platforms: [.iOS(.v17), .macOS(.v14), .tvOS(.v17), .watchOS(.v10), .visionOS(.v1)],
  products: [.library(name: "CalendarStore", targets: ["CalendarStore"])],
  dependencies: [
    .package(path: "../LandinhoFoundation"),
    .package(url: "https://github.com/pointfreeco/sqlite-data", from: "1.12.0"),
    .package(url: "https://github.com/pointfreeco/swift-dependencies", from: "1.9.0"),
  ],
  targets: [
    .target(name: "CalendarStore", dependencies: [
      .product(name: "LandinhoFoundation", package: "LandinhoFoundation"),
      .product(name: "SQLiteData", package: "sqlite-data"),
      .product(name: "Dependencies", package: "swift-dependencies"),
    ]),
    .testTarget(name: "CalendarStoreTests", dependencies: ["CalendarStore"]),
  ],
  swiftLanguageModes: [.v5]
)
