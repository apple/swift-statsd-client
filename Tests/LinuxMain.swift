//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftStatsdClient open source project
//
// Copyright (c) 2019 Apple Inc. and the SwiftStatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftStatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//
//
// LinuxMain.swift
//
import XCTest

///
/// NOTE: This file was generated by generate_linux_tests.rb
///
/// Do NOT edit this file directly as it will be regenerated automatically when needed.
///

#if os(Linux) || os(FreeBSD)
@testable import StatsdClientTests

XCTMain([
    testCase(StatsdClientIPV6Tests.allTests),
    testCase(StatsdClientTests.allTests),
])
#endif
