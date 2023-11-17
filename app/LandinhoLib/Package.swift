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
    .library(name: "Admin", targets: ["Admin"]),
    .library(name: "APIClient", targets: ["APIClient"]),
    .library(name: "Categories", targets: ["Categories"]),
    .library(name: "CategoriesAdmin", targets: ["CategoriesAdmin"]),
    .library(name: "Common", targets: ["Common"]),
    .library(name: "EventDetail", targets: ["EventDetail"]),
    .library(name: "EventsAdmin", targets: ["EventsAdmin"]),
    .library(name: "Home", targets: ["Home"]),
    .library(name: "RacesAdmin", targets: ["RacesAdmin"]),
    .library(name: "ScheduleList", targets: ["ScheduleList"]),
    .library(name: "Settings", targets: ["Settings"]),
    .library(name: "Widgets", targets: ["Widgets"]),
    .library(name: "WidgetUI", targets: ["WidgetUI"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: Version(1, 4, 2)),
  ],
  targets: [
    .target(
      name: "Admin",
      dependencies: [
        "CategoriesAdmin",
        composable
      ]),

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
          "APIClient",
          composable
        ]),

      .target(
        name: "CategoriesAdmin",
        dependencies: [
          "APIClient",
          "Common",
          "RacesAdmin",
          composable
        ]),

      .target(
        name: "EventDetail",
        dependencies: [
          "APIClient",
          composable
        ]),

      .target(
        name: "EventsAdmin",
        dependencies: [
          "APIClient",
          "Common",
          composable
        ]),

      .target(
        name: "Home",
        dependencies: [
          "Common",
          "ScheduleList",
          composable
        ]),

      .target(
        name: "RacesAdmin",
        dependencies: [
          "APIClient",
          "Common",
          "EventsAdmin",
          composable
        ]),

      .target(
        name: "ScheduleList",
        dependencies: [
          "Common",
          "EventDetail",
          "WidgetUI",
          composable
        ]),

      .target(
        name: "Settings",
        dependencies: [
          "Admin",
          "APIClient",
          composable
        ]),

      .target(
        name: "Widgets",
        dependencies: [
          "Common",
          "APIClient",
          composable
        ]),

      .target(
        name: "WidgetUI",
        dependencies: [
          "Common"
        ]),
  ]
)
