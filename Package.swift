// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "NightMode",
    platforms: [.macOS(.v14)],
    products: [.executable(name: "NightMode", targets: ["NightMode"])],
    targets: [
        .executableTarget(
            name: "NightMode",
            path: "Sources/NoxWindow",
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
