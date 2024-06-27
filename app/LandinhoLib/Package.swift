// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let apiClient = Target.Dependency.product(
  name: "APIClient",
  package: "LandinhoCore")

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let eventDetail = Target.Dependency.product(
  name: "EventDetail",
  package: "LandinhoCore")

let foundation = Target.Dependency.product(
  name: "LandinhoFoundation",
  package: "LandinhoFoundation")

let notifications = Target.Dependency.product(
  name: "NotificationsQueue",
  package: "LandinhoCoreUI")

let scheduleList = Target.Dependency.product(
  name: "ScheduleList",
  package: "LandinhoCore")

let widgetUI = Target.Dependency.product(
  name: "WidgetUI",
  package: "LandinhoCoreUI")

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
    .library(name: "EventsAdmin", targets: ["EventsAdmin"]),
    .library(name: "Home", targets: ["Home"]),
    .library(name: "RacesAdmin", targets: ["RacesAdmin"]),
    .library(name: "Router", targets: ["Router"]),
    .library(name: "Settings", targets: ["Settings"]),
    .library(name: "Sharing", targets: ["Sharing"]),
    .library(name: "Widgets", targets: ["Widgets"]),
  ],
  dependencies: [
    .package(path: "LandinhoCore"),
    .package(path: "LandinhoCoreUI"),
    .package(path: "LandinhoFoundation"),
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
          notifications,
          scheduleList,
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
        name: "EventsAdmin",
        dependencies: [
          apiClient,
          foundation,
          notifications,
          composable
        ]),

      .target(
        name: "Home",
        dependencies: [
          foundation,
          scheduleList,
          eventDetail,
          "Sharing",
          composable
        ]),

      .target(
        name: "RacesAdmin",
        dependencies: [
          apiClient,
          foundation,
          "EventsAdmin",
          notifications,
          composable
        ]),

      .target(
        name: "Router",
        dependencies: [
          "Home",
          "Categories",
          eventDetail,
          scheduleList,
          "Settings",
          "Sharing",
          composable
        ]),

      .target(
        name: "Settings",
        dependencies: [
          "Admin",
          apiClient,
          "BetaSheet",
          notifications,
          composable
        ]),

      .target(
        name: "Sharing",
        dependencies: [
          foundation,
          notifications,
          widgetUI,
          composable
        ]),

      .target(
        name: "Widgets",
        dependencies: [
          foundation,
          apiClient,
          composable
        ]),
  ]
)
