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

        let group = DispatchGroup()
        group.enter()
        statsdClient.shutdown { error in
            defer { group.leave() }
            if let error = error {
                XCTFail("unexpected error shutting down \(error)")
            }
        }
        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }
    }

    func testCounter() {
        let id = NSUUID().uuidString
        let value = Int64.random(in: 0 ... 1000)

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(value)|c", "expected entries to match")
        }

        let counter = Counter(label: id)
        counter.increment(by: value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testCounterOverflow() {
        let id = NSUUID().uuidString

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(Int64.max)|c", "expected entries to match")
        }

        let counter = Counter(label: id)
        counter.increment(by: Int64.max)
        counter.increment(by: Int64.max)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testTimerNanoseconds() {
        let id = NSUUID().uuidString
        let value = 1_234_567

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):1.234567|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordNanoseconds(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testTimerMicroseconds() {
        let id = NSUUID().uuidString
        let value = 1234

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):1.234|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordMicroseconds(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testTimerMilliseconds() {
        let id = NSUUID().uuidString
        let value = 1.234

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):1.234|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordMilliseconds(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testTimerSeconds() {
        let id = NSUUID().uuidString
        let value = 1.234

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):1234|ms", "expected entries to match")
        }

        let timer = Timer(label: id)
        timer.recordSeconds(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testGaugeInteger() {
        let id = NSUUID().uuidString
        let value = Int64.random(in: 0 ... 1000)

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(value)|g", "expected entries to match")
        }

        let guage = Gauge(label: id)
        guage.record(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testGaugeDouble() {
        let id = NSUUID().uuidString
        let value = Double.random(in: 0 ... 1000)

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(value)|g", "expected entries to match")
        }

        let guage = Gauge(label: id)
        guage.record(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testRecorderInteger() {
        let id = NSUUID().uuidString
        let value = Int64.random(in: 0 ... 1000)

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(value)|h", "expected entries to match")
        }

        let recorder = Recorder(label: id)
        recorder.record(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testRecorderDouble() {
        let id = NSUUID().uuidString
        let value = Double.random(in: 0 ... 1000)

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        let group = DispatchGroup()
        group.enter()
        server.onData { data in
            defer { group.leave() }
            XCTAssertEqual(data, "\(id):\(value)|h", "expected entries to match")
        }

        let recorder = Recorder(label: id)
        recorder.record(value)

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        try! server.shutdown()
    }

    func testCouncurrency() {
        let id = NSUUID().uuidString

        let server = TestServer(host: host, port: port)
        try! server.connect().wait()

        var results = [String]()
        let lock = Lock()

        let group = DispatchGroup()
        server.onData { data in
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

        switch group.wait(timeout: DispatchTime.now() + .seconds(1)) {
        case .timedOut:
            XCTFail("timeout")
        case .success:
            break
        }

        XCTAssertEqual(total, results.count, "expected numb of entries to match")
        for _ in 0 ..< total {
            XCTAssertEqual(results.last!, "\(id):\(1)|c", "expected entries to match")
        }

        try! server.shutdown()
    }

    class TestServer {
        let host: String
        let port: Int
        let eventLoopGroup: EventLoopGroup

        var delegate: ((String) -> Void)?

        init(host: String, port: Int) {
            self.host = host
            self.port = port
            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        }

        func connect() -> EventLoopFuture<Void> {
            let bootstrap = DatagramBootstrap(group: self.eventLoopGroup)
                .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
                .channelInitializer { channel in channel.pipeline.addHandler(Aggregator(storage: self.store)) }

            return bootstrap.bind(host: self.host, port: self.port).map { _ in Void() }
        }

        func shutdown() throws {
            try self.eventLoopGroup.syncShutdownGracefully()
        }

        func onData(delegate: @escaping (String) -> Void) {
            self.delegate = delegate
        }

        func store(value: String) {
            if let delegate = self.delegate {
                delegate(value)
            }
        }

        class Aggregator: ChannelInboundHandler {
            typealias InboundIn = AddressedEnvelope<ByteBuffer>

            let storage: (String) -> Void

            init(storage: @escaping (String) -> Void) {
                self.storage = storage
            }

            func channelRead(context: ChannelHandlerContext, data: NIOAny) {
                let envelope = self.unwrapInboundIn(data)
                let string = String(bytes: envelope.data.getBytes(at: envelope.data.readerIndex, length: envelope.data.readableBytes)!, encoding: .utf8)!
                self.storage(string)
            }
        }
    }
}
