// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Slumber",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "Slumber", targets: ["Slumber"])
    ],
    targets: [
        .executableTarget(
            name: "Slumber",
            path: ".",
            exclude: [
                "build.sh",
                "README.md",
                "LICENSE",
                "Tests"
            ],
            sources: [
                "SlumberApp.swift",
                "SlumberTimer.swift",
                "SlumberView.swift"
            ],
            resources: [
                .copy("Assets")
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "SlumberTests",
            path: "Tests/SlumberTests",
            sources: [
                "SlumberTimer.swift",
                "SlumberTimerTests.swift"
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
