// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "LandinhoBot",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/zmeyc/telegram-bot-swift.git", from: "2.0.0")
  ],
  targets: [
    .executableTarget(
      name: "LandinhoBot",
      dependencies: [
        .product(name: "TelegramBotSDK", package: "telegram-bot-swift")
      ])
  ]
)
