//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftAsyncDNSResolver open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftAsyncDNSResolver project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftAsyncDNSResolver project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

import CAsyncDNSResolver
import XCTest

@testable import AsyncDNSResolver

final class AresQueryReplyHandlerTests: XCTestCase {
    func test_noRecordsReturnsEmptyReply() async throws {
        for status in [ARES_SUCCESS, ARES_ENODATA, ARES_ENOTFOUND] {
            let reply = try await self.reply(status: status)
            XCTAssertTrue(reply.isEmpty)
        }
    }

    func test_otherErrorsArePreserved() async throws {
        for (status, expected) in [
            (ARES_ETIMEOUT, AsyncDNSResolver.Error.Code.timeout),
            (ARES_ECONNREFUSED, .connectionRefused),
            (ARES_EBADRESP, .badResponse),
            (ARES_ESERVFAIL, .internalError),
        ] {
            do {
                _ = try await self.reply(status: status)
                XCTFail("Expected an error for \(status)")
            } catch let error as AsyncDNSResolver.Error {
                XCTAssertEqual(error.code, expected)
            }
        }
    }

    private func reply(status: ares_status_t) async throws -> [SRVRecord] {
        try await withCheckedThrowingContinuation { continuation in
            let handler = Ares.QueryReplyHandler()
            XCTAssertTrue(handler.initialize(continuation, parser: Ares.SRVQueryReplyParser.instance))
            handler.handle(status: status, dnsrec: nil)
        }
    }
}
