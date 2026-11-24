// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "Whirr",
    platforms: [.macOS(.v27)],
    products: [
        .executable(name: "whirr", targets: ["Whirr"]),
    ],
    targets: [
        .executableTarget(
            name: "Whirr",
            path: "Sources/Whirr",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("ServiceManagement"),
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
