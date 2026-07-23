// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Slumber",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "Slumber", targets: ["Slumber"])
    ],
    targets: [
        .executableTarget(
            name: "Slumber",
            path: ".",
            sources: [
                "SlumberApp.swift",
                "SlumberTimer.swift",
                "SlumberView.swift"
            ],
            resources: [
                .copy("Assets")
            ]
        )
    ]
)
