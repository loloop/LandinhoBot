// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let package = Package(
  name: "LandinhoLib",
  platforms: [
    .iOS(.v17),
  ],
  products: [
    .library(name: "APIClient", targets: ["APIClient"]),
    .library(name: "Categories", targets: ["Categories"]),
    .library(name: "Common", targets: ["Common"]),
    .library(name: "EventDetail", targets: ["EventDetail"]),
    .library(name: "ScheduleList", targets: ["ScheduleList"]),
    .library(name: "Settings", targets: ["Settings"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: Version(1, 0, 0)),
  ],
  targets: [
    .target(
      name: "APIClient",
      dependencies: [
        composable
      ]),

      .target(
        name: "Common"),

      .target(
        name: "Categories",
        dependencies: [
          "ScheduleList",
          composable
        ]),

    .target(
      name: "EventDetail",
      dependencies: [
        composable
      ]),

      .target(
        name: "ScheduleList",
        dependencies: [
          "EventDetail",
          composable
        ]),

      .target(
        name: "Settings",
        dependencies: [
          "APIClient",
          composable
        ]),
  ]
)
