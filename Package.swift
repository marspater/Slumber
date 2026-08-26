// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Slumber",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "Slumber", targets: ["Slumber"])
    ],
    targets: [
        .target(
            name: "SlumberCore",
            path: "Sources/SlumberCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "Slumber",
            dependencies: [
                "SlumberCore"
            ],
            path: "Sources/Slumber",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SlumberTests",
            dependencies: [
                "SlumberCore"
            ],
            path: "Tests/SlumberTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
