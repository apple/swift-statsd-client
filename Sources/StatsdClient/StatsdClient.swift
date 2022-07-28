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

import CoreMetrics
import Dispatch
import NIO
import NIOConcurrencyHelpers

/// `StatsdClient` is a metrics backend for `SwiftMetrics`, designed to integrate applications with observability servers that support `statsd` protocol.
/// The client uses `SwiftNIO` to establish a UDP connection to the `statsd` server.
public final class StatsdClient: MetricsFactory {
    private let client: Client
    private var counters = [String: CounterHandler]() // protected by a lock
    private var recorders = [String: RecorderHandler]() // protected by a lock
    private var timers = [String: TimerHandler]() // protected by a lock
    private let lock = Lock()

    /// Create a new instance of `StatsdClient`.
    ///
    /// - Parameters:
    ///   - eventLoopGroupProvider: The ``EventLoopGroupProvider`` to use, uses ``EventLoopGroupProvider/createNew`` strategy by default.
    ///   - host: The `statsd` server host.
    ///   - port: The `statsd` server port.
    public init(
        eventLoopGroupProvider: EventLoopGroupProvider = .createNew,
        host: String,
        port: Int,
        metricNameSanitizer: @escaping StatsdClient.MetricNameSanitizer = StatsdClient.defaultMetricNameSanitizer
    ) throws {
        let address = try SocketAddress.makeAddressResolvingHost(host, port: port)
        self.client = Client(eventLoopGroupProvider: eventLoopGroupProvider, address: address, metricNameSanitizer: metricNameSanitizer)
    }

    /// Shutdown the client. This is a noop when using the ``EventLoopGroupProvider/shared(_:)`` strategy.
    ///
    /// - Note: It is required to call this method before terminating the program. `StatsdClient` will assert it was cleanly shut down as part of its destructor.
    ///
    /// - Parameters:
    ///   - callback: A callback for when shutdown is complete.
    public func shutdown(_ callback: @escaping (Error?) -> Void) {
        self.client.shutdown(callback)
    }

    // MARK: - SwiftMetric.MetricsFactory implementation

    public func makeCounter(label: String, dimensions: [(String, String)]) -> CounterHandler {
        let maker = { (label: String, dimensions: [(String, String)]) -> CounterHandler in
            StatsdCounter(label: label, dimensions: dimensions, client: self.client)
        }
        return self.lock.withLock {
            self.make(label: label, dimensions: dimensions, registry: &self.counters, maker: maker)
        }
    }

    public func makeRecorder(label: String, dimensions: [(String, String)], aggregate: Bool) -> RecorderHandler {
        let maker = { (label: String, dimensions: [(String, String)]) -> RecorderHandler in
            StatsdRecorder(label: label, dimensions: dimensions, aggregate: aggregate, client: self.client)
        }
        return self.lock.withLock {
            self.make(label: label, dimensions: dimensions, registry: &self.recorders, maker: maker)
        }
    }

    public func makeTimer(label: String, dimensions: [(String, String)]) -> TimerHandler {
        let maker = { (label: String, dimensions: [(String, String)]) -> TimerHandler in
            StatsdTimer(label: label, dimensions: dimensions, client: self.client)
        }
        return self.lock.withLock {
            self.make(label: label, dimensions: dimensions, registry: &self.timers, maker: maker)
        }
    }

    private func make<Item>(label: String, dimensions: [(String, String)], registry: inout [String: Item], maker: (String, [(String, String)]) -> Item) -> Item {
        let id = StatsdUtils.id(label: label, dimensions: dimensions, sanitizer: self.client.metricNameSanitizer)
        if let item = registry[id] {
            return item
        }
        let item = maker(label, dimensions)
        registry[id] = item
        return item
    }

    public func destroyCounter(_ handler: CounterHandler) {
        if let counter = handler as? StatsdCounter {
            self.lock.withLockVoid {
                self.counters.removeValue(forKey: counter.id)
            }
        }
    }

    public func destroyRecorder(_ handler: RecorderHandler) {
        if let recorder = handler as? StatsdRecorder {
            self.lock.withLockVoid {
                self.recorders.removeValue(forKey: recorder.id)
            }
        }
    }

    public func destroyTimer(_ handler: TimerHandler) {
        if let timer = handler as? StatsdTimer {
            self.lock.withLockVoid {
                self.timers.removeValue(forKey: timer.id)
            }
        }
    }

    /// A `EventLoopGroupProvider` defines how the underlying `EventLoopGroup` used to create the `EventLoop` is provided.
    ///
    /// When `shared`, the `EventLoopGroup` is provided externally and its lifecycle will be managed by the caller.
    /// When `createNew`, the library will create a new `EventLoopGroup` and manage its lifecycle.
    public enum EventLoopGroupProvider {
        case shared(EventLoopGroup)
        case createNew
    }
}

// MARK: - SwiftMetric.Counter implementation

private final class StatsdCounter: CounterHandler, Equatable {
    let id: String
    let client: Client
    var value = NIOAtomic<Int64>.makeAtomic(value: 0)

    init(label: String, dimensions: [(String, String)], client: Client) {
        self.id = StatsdUtils.id(label: label, dimensions: dimensions, sanitizer: client.metricNameSanitizer)
        self.client = client
    }

    public func increment(by amount: Int64) {
        self._increment(by: amount)
        // https://github.com/b/statsd_spec#counters
        // A counter is a gauge calculated at the server. Metrics sent by the client increment or decrement the value of the gauge rather than giving its current value.
        // Counters may also have an associated sample rate, given as a decimal of the number of samples per event count. For example, a sample rate of 1/10 would be exported as 0.1.
        // Valid counter values are in the range (-2^63^, 2^63^).
        _ = self.client.emit(Metric(name: self.id, value: amount, type: .counter))
    }

    private func _increment(by amount: Int64) {
        while true {
            let oldValue = self.value.load()
            guard oldValue != Int64.max else {
                return // already at max
            }
            let newValue = oldValue.addingReportingOverflow(amount)
            if self.value.compareAndExchange(expected: oldValue, desired: newValue.overflow ? Int64.max : newValue.partialValue) {
                return
            }
        }
    }

    public func reset() {
        let delta = self.value.load()
        self.value.store(0)
        _ = self.client.emit(Metric(name: self.id, value: -delta, type: .counter))
    }

    public static func == (lhs: StatsdCounter, rhs: StatsdCounter) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - SwiftMetric.Recorder implementation

private final class StatsdRecorder: RecorderHandler, Equatable {
    let id: String
    let aggregate: Bool

    let client: Client

    init(label: String, dimensions: [(String, String)], aggregate: Bool, client: Client) {
        self.id = StatsdUtils.id(label: label, dimensions: dimensions, sanitizer: client.metricNameSanitizer)
        self.aggregate = aggregate
        self.client = client
    }

    func record(_ value: Int64) {
        // https://github.com/b/statsd_spec#histograms
        // A histogram is a measure of the distribution of timer values over time, calculated at the server.
        // As the data exported for timers and histograms is the same, this is currently an alias for a timer.
        // Valid histogram values are in the range [0, 2^64^).
        // https://github.com/b/statsd_spec#gauges
        // A gauge is an instantaneous measurement of a value, like the gas gauge in a car.
        // It differs from a counter by being calculated at the client rather than the server.
        // Valid gauge values are in the range [0, 2^64^)
        let type: MetricType = self.aggregate ? .histogram : .gauge
        let value = Swift.max(0, value)
        _ = self.client.emit(Metric(name: self.id, value: value, type: type))
    }

    func record(_ value: Double) {
        // https://github.com/b/statsd_spec#histograms
        // A histogram is a measure of the distribution of timer values over time, calculated at the server.
        // As the data exported for timers and histograms is the same, this is currently an alias for a timer.
        // Valid histogram values are in the range [0, 2^64^).
        // https://github.com/b/statsd_spec#gauges
        // A gauge is an instantaneous measurement of a value, like the gas gauge in a car.
        // It differs from a counter by being calculated at the client rather than the server.
        // Valid gauge values are in the range [0, 2^64^)
        let type: MetricType = self.aggregate ? .histogram : .gauge
        let value = Swift.max(0, value)
        _ = self.client.emit(Metric(name: self.id, value: value, type: type))
    }

    public static func == (lhs: StatsdRecorder, rhs: StatsdRecorder) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - SwiftMetric.Timer implementation

private final class StatsdTimer: TimerHandler, Equatable {
    let id: String
    let client: Client

    init(label: String, dimensions: [(String, String)], client: Client) {
        self.id = StatsdUtils.id(label: label, dimensions: dimensions, sanitizer: client.metricNameSanitizer)
        self.client = client
    }

    public func recordNanoseconds(_ duration: Int64) {
        // https://github.com/b/statsd_spec#timers
        // A timer is a measure of the number of milliseconds elapsed between a start and end time, for example the time to complete rendering of a web page for a user.
        // Valid timer values are in the range [0, 2^64^).
        let value = Swift.max(0.0, Double(duration) / 1_000_000.0)
        _ = self.client.emit(Metric(name: self.id, value: value, type: .timer))
    }

    public static func == (lhs: StatsdTimer, rhs: StatsdTimer) -> Bool {
        return lhs.id == rhs.id
    }
}

// MARK: - NIO UDP Client implementation

private final class Client {
    private let eventLoopGroupProvider: StatsdClient.EventLoopGroupProvider
    private let eventLoopGroup: EventLoopGroup

    internal let metricNameSanitizer: StatsdClient.MetricNameSanitizer

    private let address: SocketAddress

    private let isShutdown = NIOAtomic<Bool>.makeAtomic(value: false)

    private var state = State.disconnected
    private let lock = Lock()

    private enum State {
        case disconnected
        case connecting(EventLoopFuture<Void>)
        case connected(Channel)
    }

    init(
        eventLoopGroupProvider: StatsdClient.EventLoopGroupProvider,
        address: SocketAddress,
        metricNameSanitizer: @escaping StatsdClient.MetricNameSanitizer
    ) {
        self.eventLoopGroupProvider = eventLoopGroupProvider
        switch self.eventLoopGroupProvider {
        case .shared(let group):
            self.eventLoopGroup = group
        case .createNew:
            self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        }
        self.metricNameSanitizer = metricNameSanitizer
        self.address = address
    }

    deinit {
        precondition(self.isShutdown.load(), "client not stopped before the deinit.")
    }

    func shutdown(_ callback: @escaping (Error?) -> Void) {
        switch self.eventLoopGroupProvider {
        case .createNew:
            if self.isShutdown.compareAndExchange(expected: false, desired: true) {
                self.eventLoopGroup.shutdownGracefully(callback)
            }
        case .shared:
            self.isShutdown.store(true)
            callback(nil)
        }
    }

    func emit(_ metric: Metric) -> EventLoopFuture<Void> {
        self.lock.lock()
        switch self.state {
        case .disconnected:
            let promise = self.eventLoopGroup.next().makePromise(of: Void.self)
            self.state = .connecting(promise.futureResult)
            self.lock.unlock()
            self.connect().flatMap { channel -> EventLoopFuture<Void> in
                self.lock.withLock {
                    guard case .connecting = self.state else {
                        preconditionFailure("invalid state \(self.state)")
                    }
                    self.state = .connected(channel)
                }
                return self.emit(metric)
            }.cascade(to: promise)
            return promise.futureResult
        case .connecting(let future):
            let future = future.flatMap {
                self.emit(metric)
            }
            self.state = .connecting(future)
            self.lock.unlock()
            return future
        case .connected(let channel):
            guard channel.isActive else {
                self.state = .disconnected
                self.lock.unlock()
                return self.emit(metric)
            }
            self.lock.unlock()
            return channel.writeAndFlush(metric)
        }
    }

    private func connect() -> EventLoopFuture<Channel> {
        let bootstrap = DatagramBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in channel.pipeline.addHandler(Encoder(address: self.address)) }
        // the bind address is local and does not really matter, the remote address is addressed by AddressedEnvelope below
        return bootstrap.bind(host: "0.0.0.0", port: 0)
    }

    private final class Encoder: ChannelOutboundHandler {
        public typealias OutboundIn = Metric
        public typealias OutboundOut = AddressedEnvelope<ByteBuffer>

        private let address: SocketAddress
        init(address: SocketAddress) {
            self.address = address
        }

        // counter: <metric name>:<value>|c[|@<sample rate>]
        // timer: <metric name>:<value>|ms
        // gauge: <metric name>:<value>|g
        // histogram: <metric name>:<value>|h
        // meter: <metric name>:<value>|m
        public func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
            let metric = self.unwrapOutboundIn(data)
            let string = "\(metric.name):\(metric.value)|\(metric.type.rawValue)"
            var buffer = context.channel.allocator.buffer(capacity: string.utf8.count)
            buffer.writeString(string)
            context.writeAndFlush(self.wrapOutboundOut(AddressedEnvelope(remoteAddress: self.address, data: buffer)), promise: promise)
        }
    }
}

// MARK: - Metric Name Sanitizer

extension StatsdClient {
    /// Used to sanitize labels (and dimensions) into a format compatible with statsd's wire format.
    ///
    /// By default `StatsdClient` uses the `StatsdClient.defaultMetricNameSanitizer`.
    public typealias MetricNameSanitizer = (String) -> String

    /// Default implementation of `LabelSanitizer` that sanitizes any ":" occurrences by replacing them with a replacement character.
    /// Defaults to replacing the illegal characters with "_", e.g. "offending:example" becomes "offending_example".
    ///
    /// See `https://github.com/b/statsd_spec` for more info.
    public static let defaultMetricNameSanitizer: StatsdClient.MetricNameSanitizer = { label in
        let illegalCharacter: Character = ":"
        let replacementCharacter: Character = "_"

        guard label.contains(illegalCharacter) else {
            return label
        }

        // replacingOccurrences would be used, but is in Foundation which we try to not depend on here
        return String(label.compactMap { (c: Character) -> Character? in
            c != illegalCharacter ? c : replacementCharacter
        })
    }
}

// MARK: - Utility

private enum StatsdUtils {
    static func id(label: String, dimensions: [(String, String)], sanitizer sanitize: StatsdClient.MetricNameSanitizer) -> String {
        if dimensions.isEmpty {
            return sanitize(label)
        } else {
            let labelWithDimensions = dimensions.reduce(label) { a, b in "\(a).\(b.0).\(b.1)" }
            return sanitize(labelWithDimensions)
        }
    }
}

private struct Metric {
    let name: String
    let value: String
    let type: MetricType

    init(name: String, value: Int64, type: MetricType) {
        self.name = name
        self.value = String(value)
        self.type = type
    }

    init(name: String, value: Double, type: MetricType) {
        self.name = name
        self.value = floor(value) != value ? String(value) : String(Int64(value))
        self.type = type
    }
}

private enum MetricType: String {
    case gauge = "g"
    case counter = "c"
    case timer = "ms"
    case histogram = "h"
    case meter = "m"
}

private final class Box<T> {
    let value: T
    init(_ value: T) {
        self.value = value
    }
}
