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
#if canImport(Atomics)
import Atomics
#else
import NIOConcurrencyHelpers
#endif

internal class Atomic<T: AtomicValue> {
    #if canImport(Atomics)
    private let managed: ManagedAtomic<T>
    #else
    private let nio: NIOAtomic<T>
    #endif

    init(_ value: T) {
        #if canImport(Atomics)
        self.managed = ManagedAtomic(value)
        #else
        self.nio = NIOAtomic.makeAtomic(value: value)
        #endif
    }

    func load() -> T {
        #if canImport(Atomics)
        return self.managed.load(ordering: .sequentiallyConsistent)
        #else
        return self.nio.load()
        #endif
    }

    func compareExchange(expected: T, desired: T) -> Bool {
        #if canImport(Atomics)
        return self.managed.compareExchange(
            expected: expected,
            desired: desired,
            ordering: .sequentiallyConsistent
        ).exchanged
        #else
        return self.nio.compareAndExchange(expected: expected, desired: desired)
        #endif
    }

    func store(_ value: T) {
        #if canImport(Atomics)
        self.managed.store(value, ordering: .sequentiallyConsistent)
        #else
        self.nio.store(value)
        #endif
    }
}
