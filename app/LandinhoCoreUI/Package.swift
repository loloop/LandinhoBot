// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let foundation = Target.Dependency.product(
  name: "LandinhoFoundation",
  package: "LandinhoFoundation")

let package = Package(
    name: "LandinhoCoreUI",
    platforms: [
      .iOS(.v17),
      .tvOS(.v17),
      .macOS(.v14),
      .visionOS(.v1),
      .watchOS(.v10)
    ],
    products: [
      .library(name: "CategoryUI", targets: ["CategoryUI"]),
      .library(name: "NotificationsQueue", targets: ["NotificationsQueue"]),
      .library(name: "WidgetUI", targets: ["WidgetUI"]),
    ],
    dependencies: [
      .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        from: Version(1, 26, 2)),
      .package(path: "../LandinhoFoundation")
    ],
    targets: [
      .target(name: "CategoryUI", dependencies: [foundation]),
      .target(
        name: "NotificationsQueue",
        dependencies: [
          composable
        ]),

        .target(
          name: "WidgetUI",
          dependencies: [
            foundation,
            "CategoryUI",
          ]),
        .testTarget(name: "WidgetUITests", dependencies: ["WidgetUI"]),
    ]
)
