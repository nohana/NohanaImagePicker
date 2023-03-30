// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "NohanaImagePicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v13),
        .macOS(.v11)
    ],
    products: [
        .library(
            name: "NohanaImagePicker",
            targets: ["NohanaImagePicker"]),
    ],
    targets: [
        .target(
            name: "NohanaImagePicker",
            path: "NohanaImagePicker",
            resources: [.process("NohanaImagePicker.strings")])
    ],
    swiftLanguageVersions: [.v5]
)
