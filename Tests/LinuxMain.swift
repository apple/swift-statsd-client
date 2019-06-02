//===----------------------------------------------------------------------===//
//
// This source file is part of the StatsdClient open source project
//
// Copyright (c) 2017-2018 the StatsdClient project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of StatsdClient project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import XCTest

import StatsdClientTests

var tests = [XCTestCaseEntry]()
tests += StatsdClientTests.__allTests()

XCTMain(tests)
