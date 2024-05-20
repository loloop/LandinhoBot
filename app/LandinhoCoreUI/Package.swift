// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

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
      .library(name: "NotificationsQueue", targets: ["NotificationsQueue"]),
    ],
    dependencies: [
      .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        from: Version(1, 5, 0)),
      .package(path: "LandinhoFoundation")
    ],
    targets: [
      .target(
        name: "NotificationsQueue",
        dependencies: [
          composable
        ]),
    ]
)
