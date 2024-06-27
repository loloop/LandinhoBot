// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let widgetUI = Target.Dependency.product(
  name: "WidgetUI",
  package: "LandinhoCoreUI")

let foundation = Target.Dependency.product(
  name: "LandinhoFoundation",
  package: "LandinhoFoundation")

let package = Package(
    name: "LandinhoCore",
    platforms: [
      .iOS(.v17),
      .tvOS(.v17),
      .macOS(.v14),
      .visionOS(.v1),
      .watchOS(.v10)
    ],
    products: [
      .library(name: "APIClient", targets: ["APIClient"]),
      .library(name: "EventDetail", targets: ["EventDetail"]),
      .library(name: "ScheduleList", targets: ["ScheduleList"]),
    ],
    dependencies: [
      .package(path: "LandinhoCoreUI"),
      .package(path: "LandinhoFoundation"),
      .package(
        url: "https://github.com/pointfreeco/swift-composable-architecture",
        from: Version(1, 5, 0)),
    ],
    targets: [
      .target(
        name: "APIClient",
        dependencies: [
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          composable
        ]),

        .target(
          name: "EventDetail",
          dependencies: [
            "APIClient",
            widgetUI,
            composable
          ]),

        .target(
          name: "ScheduleList",
          dependencies: [
            foundation,
            "EventDetail",
            widgetUI,
            composable
          ]),
    ]
)
