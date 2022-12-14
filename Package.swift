// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Chip8",
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "Chip8",
      targets: ["Chip8"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/Quick/Quick", from: "5.0.1"),
    .package(url: "https://github.com/Quick/Nimble", from: "10.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Chip8",
      dependencies: []),
    .testTarget(
      name: "Chip8Tests",
      dependencies: [
        "Chip8",
        "Quick",
        "Nimble",
      ],
      resources: [
        .copy("testdata"),
      ]),
  ]
)
