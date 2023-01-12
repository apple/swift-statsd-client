//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftStatsdClient open source project
//
// Copyright (c) 2019-2023 the SwiftStatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftStatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

@testable import CoreMetrics
import NIOCore
@testable import StatsdClient
import XCTest

private let host = "::1"
private let port = 9999
private var statsdClient: StatsdClient!

class StatsdClientIPV6Tests: XCTestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()

        try XCTSkipUnless(System.supportsIPv6)

        statsdClient = try! StatsdClient(host: host, port: port)
        MetricsSystem.bootstrapInternal(statsdClient)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        try XCTSkipUnless(System.supportsIPv6)

        let semaphore = DispatchSemaphore(value: 0)
        statsdClient.shutdown { error in
            defer { semaphore.signal() }
            if let error = error {
                XCTFail("unexpected error shutting down \(error)")
            }
        }

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testIPV6Address() throws {
        try XCTSkipUnless(System.supportsIPv6)

        let server = TestServer(host: "::1", port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, _ in
            semaphore.signal()
        }

        let counter = Counter(label: UUID().uuidString)
        counter.increment(by: 12)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }
}

extension System {
    static var supportsIPv6: Bool {
        do {
            let ipv6Loopback = try SocketAddress.makeAddressResolvingHost("::1", port: 0)
            return try System.enumerateDevices().filter { $0.address == ipv6Loopback }.first != nil
        } catch {
            return false
        }
    }
}
