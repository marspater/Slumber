// swift-tools-version: 5.9
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
                "LICENSE"
            ],
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
