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
                "working resources"
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
        )
    ]
)
