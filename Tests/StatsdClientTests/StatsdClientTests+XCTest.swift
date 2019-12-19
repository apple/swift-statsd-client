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
//
// StatsdClientTests+XCTest.swift
//
import XCTest

///
/// NOTE: This file was generated by generate_linux_tests.rb
///
/// Do NOT edit this file directly as it will be regenerated automatically when needed.
///

extension StatsdClientTests {
    static var allTests: [(String, (StatsdClientTests) -> () throws -> Void)] {
        return [
            ("testCounter", testCounter),
            ("testCounterOverflow", testCounterOverflow),
            ("testTimerNanoseconds", testTimerNanoseconds),
            ("testTimerMicroseconds", testTimerMicroseconds),
            ("testTimerMilliseconds", testTimerMilliseconds),
            ("testTimerSeconds", testTimerSeconds),
            ("testGaugeInteger", testGaugeInteger),
            ("testGaugeDouble", testGaugeDouble),
            ("testRecorderInteger", testRecorderInteger),
            ("testRecorderDouble", testRecorderDouble),
            ("testCouncurrency", testCouncurrency),
        ]
    }
}
