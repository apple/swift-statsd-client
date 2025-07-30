//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftStatsdClient open source project
//
// Copyright (c) 2019-2023 Apple Inc. and the SwiftStatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftStatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import Foundation
import NIO
import NIOConcurrencyHelpers
import XCTest

@testable import StatsdClient

final class TestServer: @unchecked Sendable {
    let host: String
    let port: Int
    let eventLoopGroup: EventLoopGroup

    let lock = NIOLock()
    private var locked_delegate: ((SocketAddress, String) -> Void)?

    init(host: String, port: Int) {
        self.host = host
        self.port = port
        self.eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: 1)
    }

    func connect() -> EventLoopFuture<Void> {
        let bootstrap = DatagramBootstrap(group: self.eventLoopGroup)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelInitializer { channel in channel.pipeline.addHandler(Aggregator(delegate: { self.store(address: $0, value: $1) })) }

        return bootstrap.bind(host: self.host, port: self.port).map { _ in () }
    }

    func shutdown() throws {
        try self.eventLoopGroup.syncShutdownGracefully()
    }

    func onData(delegate: @escaping (SocketAddress, String) -> Void) {
        self.lock.withLock {
            self.locked_delegate = delegate
        }
    }

    func store(address: SocketAddress, value: String) {
        if let delegate = self.lock.withLock({ self.locked_delegate }) {
            delegate(address, value)
        }
    }

    final class Aggregator: ChannelInboundHandler, Sendable {
        typealias InboundIn = AddressedEnvelope<ByteBuffer>

        let delegate: @Sendable (SocketAddress, String) -> Void

        init(delegate: @escaping @Sendable (SocketAddress, String) -> Void) {
            self.delegate = delegate
        }

        func channelRead(context: ChannelHandlerContext, data: NIOAny) {
            let envelope = self.unwrapInboundIn(data)
            let string = String(
                bytes: envelope.data.getBytes(at: envelope.data.readerIndex, length: envelope.data.readableBytes)!,
                encoding: .utf8
            )!
            self.delegate(envelope.remoteAddress, string)
        }
    }
}
