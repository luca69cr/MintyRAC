// swift-tools-version:4.2

import PackageDescription

let package = Package(
    name: "MintyRAC",
    products: [
        .library(name: "MintyRAC", targets: ["App"]),
    ],
    dependencies: [
        /// 💧 A server-side Swift web framework.
        .package(url: "https://github.com/vapor/vapor.git", from: "3.0.0"),
        /// 🧩 Swift ORM (queries, models, relations, etc) built on SQLite 3.
        .package(url: "https://github.com/vapor/fluent-sqlite.git", from: "3.0.0"),
        /// 🧩 WebSocket build on NIO.
        .package(url: "https://github.com/vapor/websocket.git", from: "1.0.0"),
        /// 🧩  Redis build on NIO.
        .package(url: "https://github.com/vapor/redis.git", from: "3.0.0")
        
    ],
    targets: [
        .target(name: "App", dependencies: ["FluentSQLite", "Vapor","WebSocket","Redis"]),
        .target(name: "Run", dependencies: ["App"]),
        .testTarget(name: "AppTests", dependencies: ["App"])
    ]
)

