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

import XCTest
@testable import CoreMetrics
@testable import StatsdClient

private let host = "::1"
private let port = 9999
private var statsdClient: StatsdClient!

class StatsdClientIPV6Tests: XCTestCase {

    override class func setUp() {
        super.setUp()

        statsdClient = try! StatsdClient(host: host, port: port)
        MetricsSystem.bootstrapInternal(statsdClient)
    }
    
    override class func tearDown() {
        super.tearDown()

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
