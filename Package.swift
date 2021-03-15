// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PersistenceKit",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v11),
        .iOS(.v14)
    ],
    products: [
        .library(name: "PersistenceKit", targets: ["PersistenceKit"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "PersistenceKit", dependencies: []),
        .testTarget(name: "PersistenceKitTests", dependencies: ["PersistenceKit"]),
    ]
)
