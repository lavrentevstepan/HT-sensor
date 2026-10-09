// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MinewBeaconScanner",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "MinewBeaconScanner",
            targets: ["MinewBeaconScanner"]
        ),
    ],
    targets: [
        .target(
            name: "MinewBeaconScanner",
            path: "MinewBeaconScanner"
        ),
        .testTarget(
            name: "MinewBeaconScannerTests",
            dependencies: ["MinewBeaconScanner"],
            path: "MinewBeaconScannerTests"
        ),
    ]
)
