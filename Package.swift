// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "MyNightMode",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "MyNightMode", targets: ["MyNightMode"])],
    targets: [
        .executableTarget(
            name: "MyNightMode",
            path: "Sources/NoxWindow",
            resources: [.process("Resources")],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("CoreImage"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Carbon"),
                .linkedFramework("IOKit")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
