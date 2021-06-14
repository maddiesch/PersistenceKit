// swift-tools-version:5.4
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
        .library(name: "ModelBuilder", targets: ["ModelBuilder"])
    ],
    dependencies: [],
    targets: [
        .target(name: "PersistenceKit", dependencies: []),
        .target(name: "ModelBuilder", dependencies: []),
        .testTarget(name: "PersistenceKitTests", dependencies: ["PersistenceKit"]),
        .testTarget(name: "ModelBuilderTests", dependencies: ["ModelBuilder"]),
    ]
)
