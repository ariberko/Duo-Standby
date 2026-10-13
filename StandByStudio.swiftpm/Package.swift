// swift-tools-version: 5.9

// Open this folder in Swift Playgrounds on iPad to preview every design.
// It has no real widgets or purchases. Those need the Xcode project.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "StandBy Studio Preview",
    platforms: [
        .iOS("17.0")
    ],
    products: [
        .iOSApplication(
            name: "StandBy Studio Preview",
            targets: ["AppModule"],
            bundleIdentifier: "com.ariberko.standbystudio.preview",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .clock),
            accentColor: .presetColor(.orange),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "."
        )
    ]
)
