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

#if canImport(Darwin)
import dnssd
import XCTest

@testable import AsyncDNSResolver

final class DNSSDQueryReplyHandlerTests: XCTestCase {
    func test_noSuchRecordReturnsEmptyReply() async throws {
        let reply = try await self.reply(errorCode: Int32(kDNSServiceErr_NoSuchRecord))
        XCTAssertTrue(reply.isEmpty)
    }

    func test_timeoutStillReturnsEmptyReply() async throws {
        let reply = try await self.reply(errorCode: Int32(kDNSServiceErr_Timeout))
        XCTAssertTrue(reply.isEmpty)
    }

    func test_otherErrorsArePreserved() async throws {
        for (code, expected) in [
            (kDNSServiceErr_Refused, AsyncDNSResolver.Error.Code.connectionRefused),
            (kDNSServiceErr_BadParam, .badQuery),
            (kDNSServiceErr_Unknown, .internalError),
        ] {
            do {
                _ = try await self.reply(errorCode: Int32(code))
                XCTFail("Expected an error for \(code)")
            } catch let error as AsyncDNSResolver.Error {
                XCTAssertEqual(error.code, expected)
            }
        }
    }

    private func reply(errorCode: DNSServiceErrorType) async throws -> [SRVRecord] {
        let stream = AsyncThrowingStream<SRVRecord, Error> { continuation in
            let handler = DNSSD.QueryReplyHandler(handler: DNSSD.SRVQueryReplyHandler.instance, continuation)
            handler.handleRecord(errorCode: errorCode, data: nil, length: 0)
        }
        var records: [SRVRecord] = []
        for try await record in stream {
            records.append(record)
        }
        return try DNSSD.SRVQueryReplyHandler.instance.generateReply(records: records)
    }
}
#endif
