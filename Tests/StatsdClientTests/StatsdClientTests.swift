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

import CoreMetrics
import NIO
import NIOConcurrencyHelpers
@testable import StatsdClient
import XCTest

private let host = "127.0.0.1"
private let port = 9999
private var statsdClient: StatsdClient!

class StatsdClientTests: XCTestCase {
    override class func setUp() {
        super.setUp()

        statsdClient = try! StatsdClient(host: host, port: port)
        MetricsSystem.bootstrap(statsdClient)
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

    func testCounter() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = Int64.random(in: 0 ... 1000)

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):\(value)|c", "expected entries to match")
        }

        let counter = Counter(label: id)
        counter.increment(by: value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testCounterOverflow() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString

        let group = DispatchGroup()
        group.enter()
        group.enter()
        server.onData { _, data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(Int64.max)|c", "expected entries to match")
        }

        let counter = Counter(label: id)
        counter.increment(by: Int64.max)
        counter.increment(by: Int64.max)

        assertTimeoutResult(group.wait(timeout: .now() + .seconds(1)))
    }

    func testTimerNanoseconds() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = 1_234_567

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):1.234567|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordNanoseconds(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testTimerMicroseconds() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = 1234

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):1.234|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordMicroseconds(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testTimerMilliseconds() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = 1.234

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):1.234|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordMilliseconds(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testTimerSeconds() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = 1.234

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):1234|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordSeconds(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testGaugeInteger() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = Int64.random(in: 0 ... 1000)

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):\(value)|g", "expected entries to match")
        }

        let guage = Gauge(label: id)
        guage.record(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testGaugeDouble() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = Double.random(in: 0 ... 1000)

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):\(value)|g", "expected entries to match")
        }

        let guage = Gauge(label: id)
        guage.record(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testRecorderInteger() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = Int64.random(in: 0 ... 1000)

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):\(value)|h", "expected entries to match")
        }

        let recorder = Recorder(label: id)
        recorder.record(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testRecorderDouble() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString
        let value = Double.random(in: 0 ... 1000)

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(id):\(value)|h", "expected entries to match")
        }

        let recorder = Recorder(label: id)
        recorder.record(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testLabelSanitizer() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let illegalID = "hello/:who"
        let sanitizedID = "hello/_who"
        let value = Double.random(in: 0 ... 1000)

        let semaphore = DispatchSemaphore(value: 0)
        server.onData { _, data in
            defer { semaphore.signal() }
            XCTAssertEqual(data, "\(sanitizedID):\(value)|h", "expected entries to match")
        }

        let recorder = Recorder(label: illegalID)
        recorder.record(value)

        assertTimeoutResult(semaphore.wait(timeout: .now() + .seconds(1)))
    }

    func testCouncurrency() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        let id = UUID().uuidString

        var results = [String]()
        let lock = Lock()

        let group = DispatchGroup()
        server.onData { _, data in
            defer { group.leave() }
            lock.withLock {
                results.append(data)
            }
        }

        let queue = DispatchQueue(label: "testCouncurrency")
        let total = Int.random(in: 300 ... 500)
        for _ in 0 ..< total {
            group.enter()
            queue.async {
                let counter = Counter(label: id)
                counter.increment(by: 1)
            }
        }

        assertTimeoutResult(group.wait(timeout: .now() + .seconds(1)))
        XCTAssertEqual(total, results.count, "expected numb of entries to match")
        for _ in 0 ..< total {
            XCTAssertEqual(results.last!, "\(id):\(1)|c", "expected entries to match")
        }
    }

    func testNumberOfConnections() {
        let server = TestServer(host: host, port: port)
        XCTAssertNoThrow(try server.connect().wait())
        defer { XCTAssertNoThrow(try server.shutdown()) }

        var clients = Set<String>()

        let group = DispatchGroup()
        server.onData { address, _ in
            group.leave()
            clients.insert(address.description)
        }

        let total = Int.random(in: 300 ... 500)
        for _ in 0 ..< total {
            group.enter()
            let counter = Counter(label: "test")
            counter.increment(by: 1)
        }

        assertTimeoutResult(group.wait(timeout: .now() + .seconds(1)))
        XCTAssertEqual(clients.count, 1, "expect one client")
    }

    class TestServer {
        let host: String
        let port: Int
        let eventLoopGroup: EventLoopGroup

        var delegate: ((SocketAddress, String) -> Void)?

        init(host: String, port: Int) {
            self.host = host
            self.port = port
            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        }

        func connect() -> EventLoopFuture<Void> {
            let bootstrap = DatagramBootstrap(group: self.eventLoopGroup)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelInitializer { channel in channel.pipeline.addHandler(Aggregator(delegate: self.store)) }

            return bootstrap.bind(host: self.host, port: self.port).map { _ in Void() }
        }

        func shutdown() throws {
            try self.eventLoopGroup.syncShutdownGracefully()
        }

        func onData(delegate: @escaping (SocketAddress, String) -> Void) {
            self.delegate = delegate
        }

        func store(address: SocketAddress, value: String) {
            if let delegate = self.delegate {
                delegate(address, value)
            }
        }

        class Aggregator: ChannelInboundHandler {
            typealias InboundIn = AddressedEnvelope<ByteBuffer>

            let delegate: (SocketAddress, String) -> Void

            init(delegate: @escaping (SocketAddress, String) -> Void) {
                self.delegate = delegate
            }

            func channelRead(context: ChannelHandlerContext, data: NIOAny) {
                let envelope = self.unwrapInboundIn(data)
                let string = String(bytes: envelope.data.getBytes(at: envelope.data.readerIndex, length: envelope.data.readableBytes)!, encoding: .utf8)!
                self.delegate(envelope.remoteAddress, string)
            }
        }
    }
}

func assertTimeoutResult(_ result: DispatchTimeoutResult) {
    if case .timedOut = result {
        XCTFail("timeout")
    }
}
