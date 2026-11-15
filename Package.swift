// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Slumbr",
    platforms: [
        .macOS("26.0")
    ],
    products: [
        .executable(name: "Slumbr", targets: ["Slumbr"])
    ],
    targets: [
        .target(
            name: "SlumbrCore",
            path: "Sources/SlumbrCore",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .executableTarget(
            name: "Slumbr",
            dependencies: [
                "SlumbrCore"
            ],
            path: "Sources/Slumbr",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SlumbrTests",
            dependencies: [
                "SlumbrCore"
            ],
            path: "Tests/SlumbrTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
