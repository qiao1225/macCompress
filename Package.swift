// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "macCompress",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "macCompress",
            targets: ["macCompress"]
        )
    ],
    targets: [
        .executableTarget(
            name: "macCompress",
            path: "Sources/macCompress"
        ),
        .testTarget(
            name: "macCompressTests",
            dependencies: ["macCompress"],
            path: "Tests/macCompressTests"
        )
    ]
)
