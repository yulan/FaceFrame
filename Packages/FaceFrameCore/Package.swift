// swift-tools-version: 6.0
import PackageDescription

// Domain depends on nothing. DataLayer depends on Domain.
let package = Package(
    name: "FaceFrameCore",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "DataLayer", dependencies: ["Domain"]),
        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "DataLayerTests", dependencies: ["DataLayer", "Domain"]),
    ],
    swiftLanguageModes: [.v6]
)
