// swift-tools-version: 6.0
import PackageDescription

/// Same split as OpenWeatherMVVM-C, so the dependency rule is enforced by the compiler:
///
///   App (Presentation)  ──▶  DataLayer (AVFoundation, Vision)  ──▶  Domain (pure Swift)
///          └──────────────────────────────────────────────────────▲
///
/// `Domain` holds the geometry and the maths and imports only Foundation,
/// so everything that can be unit-tested without a camera lives there.
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
