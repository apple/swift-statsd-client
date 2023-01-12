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

import Foundation
import NIO
@testable import StatsdClient
import XCTest

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
