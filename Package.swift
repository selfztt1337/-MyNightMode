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
            exclude: [
                "Services/CaptureOutput.swift",
                "Services/FrameRenderer.swift",
                "Services/PermissionService.swift",
                "Services/WindowCatalog.swift"
            ],
            resources: [.process("Resources")],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("Carbon"),
                .linkedFramework("IOKit")
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
