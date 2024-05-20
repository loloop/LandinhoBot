// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let apiClient = Target.Dependency.product(
  name: "APIClient",
  package: "LandinhoCore")

let package = Package(
  name: "LandinhoLib",
  platforms: [
    .iOS(.v17),
  ],
  products: [
    .library(name: "Admin", targets: ["Admin"]),
    .library(name: "BetaSheet", targets: ["BetaSheet"]),
    .library(name: "Categories", targets: ["Categories"]),
    .library(name: "CategoriesAdmin", targets: ["CategoriesAdmin"]),
    .library(name: "EventDetail", targets: ["EventDetail"]),
    .library(name: "EventsAdmin", targets: ["EventsAdmin"]),
    .library(name: "Home", targets: ["Home"]),
    .library(name: "RacesAdmin", targets: ["RacesAdmin"]),
    .library(name: "Router", targets: ["Router"]),
    .library(name: "ScheduleList", targets: ["ScheduleList"]),
    .library(name: "Settings", targets: ["Settings"]),
    .library(name: "Sharing", targets: ["Sharing"]),
    .library(name: "Widgets", targets: ["Widgets"]),
    .library(name: "WidgetUI", targets: ["WidgetUI"]),
  ],
  dependencies: [
    .package(name: "LandinhoCore", path: "LandinhoCore"),
    .package(name: "LandinhoCoreUI", path: "LandinhoCoreUI"),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: Version(1, 5, 0)),

  ],
  targets: [
    .target(
      name: "Admin",
      dependencies: [
        "CategoriesAdmin",
        composable
      ]),

      .target(
        name: "BetaSheet",
        dependencies: [
          composable
        ]),

      .target(
        name: "Categories",
        dependencies: [
          apiClient,
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          "ScheduleList",
          composable
        ]),

      .target(
        name: "CategoriesAdmin",
        dependencies: [
          apiClient,
          .product(name: "Common", package: "LandinhoCore"),
          "RacesAdmin",
          composable
        ]),

      .target(
        name: "EventDetail",
        dependencies: [
          apiClient,
          "WidgetUI",
          composable
        ]),

      .target(
        name: "EventsAdmin",
        dependencies: [
          apiClient,
          .product(name: "Common", package: "LandinhoCore"),
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          composable
        ]),

      .target(
        name: "Home",
        dependencies: [
          .product(name: "Common", package: "LandinhoCore"),
          "ScheduleList",
          "EventDetail",
          "Sharing",
          composable
        ]),

      .target(
        name: "RacesAdmin",
        dependencies: [
          apiClient,
          .product(name: "Common", package: "LandinhoCore"),
          "EventsAdmin",
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          composable
        ]),

      .target(
        name: "Router",
        dependencies: [
          "Home",
          "Categories",
          "EventDetail",
          "ScheduleList",
          "Settings",
          "Sharing",
          composable
        ]),

      .target(
        name: "ScheduleList",
        dependencies: [
          .product(name: "Common", package: "LandinhoCore"),
          "EventDetail",
          "WidgetUI",
          composable
        ]),

      .target(
        name: "Settings",
        dependencies: [
          "Admin",
          apiClient,
          "BetaSheet",
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          composable
        ]),

      .target(
        name: "Sharing",
        dependencies: [
          .product(name: "Common", package: "LandinhoCore"),
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          "WidgetUI",
          composable
        ]),

      .target(
        name: "Widgets",
        dependencies: [
          .product(name: "Common", package: "LandinhoCore"),
          apiClient,
          composable
        ]),

      .target(
        name: "WidgetUI",
        dependencies: [
          .product(name: "Common", package: "LandinhoCore")
        ]),
  ]
)
