// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let composable = Target.Dependency.product(
  name: "ComposableArchitecture",
  package: "swift-composable-architecture")

let package = Package(
  name: "AdminLib",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v17)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(name: "AdminLib", targets: ["AdminLib"]),
    .library(name: "APIClient", targets: ["APIClient"]),
    .library(name: "APIRequester", targets: ["APIRequester"]),
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture",
      from: Version(1, 0, 0)),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "AdminLib",
      dependencies: [
        "APIClient",
        composable,
      ]
    ),
    
    .testTarget(
      name: "AdminLibTests",
      dependencies: ["AdminLib"]),

    .target(
      name: "APIClient",
      dependencies: [
        "APIRequester",
        composable
      ]),

    .target(
      name: "APIRequester",
      dependencies: [
        composable
      ]),
  ]
)
