//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftStatsdClient open source project
//
// Copyright (c) 2019 the SwiftStatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftStatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest
import CoreMetrics
@testable import StatsdClient

private let port = 9999

class StatsdClientIPV6Tests: XCTestCase {

    func testIPV6Address() throws {
        let server = TestServer(host: "::1", port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }
        
        var data = [String]()

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, line in
            semaphore.signal()

            data.append(line)
        }
        
        let client = try StatsdClient(host: "::1", port: port)
        MetricsSystem.bootstrap(client)
        
        let counter = Counter(label: UUID().uuidString)
        counter.increment(by: 12)
        
        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))

        XCTAssertEqual(data.count, 1)
    }
}
