// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LandinhoFoundation",
    platforms: [
      .iOS(.v17),
      .tvOS(.v17),
      .macOS(.v14),
      .visionOS(.v1),
      .watchOS(.v10)
    ],
    products: [
      .library(
        name: "LandinhoFoundation",
        targets: ["LandinhoFoundation"]
      ),
    ],
    targets: [
      .target(name: "LandinhoFoundation")
    ]
)
