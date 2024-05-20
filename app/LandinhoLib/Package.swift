// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let apiClient = Target.Dependency.product(
  name: "APIClient",
  package: "LandinhoCore")

let foundation = Target.Dependency.product(
  name: "LandinhoFoundation",
  package: "LandinhoFoundation")

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
    .package(name: "LandinhoFoundation", path: "LandinhoFoundation"),
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
          foundation,
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
          foundation,
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          composable
        ]),

      .target(
        name: "Home",
        dependencies: [
          foundation,
          "ScheduleList",
          "EventDetail",
          "Sharing",
          composable
        ]),

      .target(
        name: "RacesAdmin",
        dependencies: [
          apiClient,
          foundation,
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
          foundation,
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
          foundation,
          .product(name: "NotificationsQueue", package: "LandinhoCoreUI"),
          "WidgetUI",
          composable
        ]),

      .target(
        name: "Widgets",
        dependencies: [
          foundation,
          apiClient,
          composable
        ]),

      .target(
        name: "WidgetUI",
        dependencies: [
          foundation,
        ]),
  ]
)
