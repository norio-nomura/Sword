// swift-tools-version:4.0

import PackageDescription

var dependencies: [Package.Dependency] = [
  .package(
    url: "https://github.com/norio-nomura/Sodium.git",
    .upToNextMajor(from: "1.0.0")
  ),
  .package(
    url: "https://github.com/norio-nomura/MimeType.git",
    .upToNextMajor(from: "1.0.0")
  )
]

var targetDeps: [Target.Dependency] = ["MimeType"]

#if !os(Linux)
dependencies += [
  .package(
    url: "https://github.com/daltoniam/Starscream.git",
    .upToNextMajor(from: "3.0.0")
  ),
  .package(
    url: "https://github.com/vapor/sockets.git",
    .upToNextMajor(from: "2.0.0")
  )
]
  
targetDeps += ["Starscream", "Sockets"]
#else
dependencies += [
  .package(
    url: "https://github.com/vapor/engine.git",
    .upToNextMajor(from: "2.0.0")
  )
]
  
targetDeps += ["URI", "WebSockets"]
#endif

let package = Package(
  name: "Sword",
  products: [
    .library(name: "Sword", targets: ["Sword"])
  ],
  dependencies: dependencies,
  targets: [
    .target(
      name: "Sword",
      dependencies: targetDeps
    )
  ]
)
