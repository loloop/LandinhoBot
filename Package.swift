// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LandinhoBot",
  dependencies: [
    .package(url: "https://github.com/zmeyc/telegram-bot-swift.git", from: "2.0.0"),
    .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.13.0")
  ],
  targets: [
    .executableTarget(
      name: "LandinhoBot",
      dependencies: [
        .product(name: "TelegramBotSDK", package: "telegram-bot-swift"),
        "OpenCombine",
        .product(name: "OpenCombineFoundation", package: "OpenCombine"),
      ])
  ]
)
