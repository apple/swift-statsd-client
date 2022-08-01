// swift-tools-version:5.6

//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftStatsdClient open source project
//
// Copyright (c) 2019-2022 the SwiftStatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftStatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import PackageDescription

let package = Package(
    name: "swift-statsd-client",
    products: [
        .library(name: "StatsdClient", targets: ["StatsdClient"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-metrics.git", "1.0.0" ..< "3.0.0"),
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.0.0"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
    ],
    targets: [
        .target(name: "StatsdClient", dependencies: [
            .product(name: "CoreMetrics", package: "swift-metrics"),
            .product(name: "NIO", package: "swift-nio"),
        ]),
        .testTarget(name: "StatsdClientTests", dependencies: ["StatsdClient"]),
    ]
)
