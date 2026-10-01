// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "LandinhoClip",
  platforms: [.iOS(.v17), .macOS(.v14)],
  products: [.library(name: "AppClipFeature", targets: ["AppClipFeature"])],
  dependencies: [.package(path: "../LandinhoFoundation")],
  targets: [
    .target(name: "AppClipFeature", dependencies: [.product(name: "LandinhoFoundation", package: "LandinhoFoundation")]),
    .testTarget(name: "AppClipFeatureTests", dependencies: ["AppClipFeature"])
  ])
