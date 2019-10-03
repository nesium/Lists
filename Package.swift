// swift-tools-version:5.1

import PackageDescription

let package = Package(
  name: "Lists",
  platforms: [
    .iOS(.v11)
  ],
  products: [
    .library(name: "Lists", targets: ["Lists"]),
  ],
  dependencies: [
    .package(url: "https://github.com/ReactiveX/RxSwift.git", .upToNextMajor(from: "5.0.1")),
    .package(url: "https://github.com/nesium/IGListKit.git", .upToNextMajor(from: "3.4.1")),
    .package(url: "https://github.com/nesium/SwipeCellKit.git", .upToNextMajor(from: "1.9.2")),
    .package(url: "https://github.com/nesium/Bindings.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/nesium/NSMUIKit.git", .upToNextMajor(from: "1.0.0")),
    .package(url: "https://github.com/nesium/NSMFoundation.git", .upToNextMajor(from: "1.0.0"))
  ],
  targets: [
    .target(
      name: "Lists", 
      dependencies: [
        "RxSwift", 
        "IGListKit",
        "SwipeCellKit",
        "Bindings", 
        "NSMUIKit",
        "NSMFoundation"
      ]
    )
  ]
)
