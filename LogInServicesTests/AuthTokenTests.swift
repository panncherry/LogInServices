//
//  AuthTokenTests.swift
//  LogInServicesTests
//

import XCTest
@testable import LogInServices

final class AuthTokenTests: XCTestCase {
    func testValidTokenWithinLifetime() {
        let base = Date(timeIntervalSince1970: 2_000_000_000)
        let token = AuthToken(accessToken: "abc", expiresAt: base.addingTimeInterval(3600))
        XCTAssertTrue(token.isValid(at: base))
        XCTAssertTrue(token.isValid(at: base.addingTimeInterval(100)))
    }

    func testEmptyAccessTokenIsInvalid() {
        let base = Date()
        let token = AuthToken(accessToken: "", expiresAt: base.addingTimeInterval(3600))
        XCTAssertFalse(token.isValid(at: base))
    }

    func testExpiredTokenRejected() {
        let base = Date(timeIntervalSince1970: 2_000_000_000)
        let token = AuthToken(accessToken: "abc", expiresAt: base.addingTimeInterval(60))
        XCTAssertFalse(token.isValid(at: base.addingTimeInterval(120)))
    }

    func testLeewayTreatsNearExpiryAsInvalid() {
        let expiry = Date(timeIntervalSince1970: 2_000_000_000)
        let token = AuthToken(accessToken: "abc", expiresAt: expiry)
        let almostThere = expiry.addingTimeInterval(-30)
        XCTAssertFalse(token.isValid(at: almostThere, leeway: 60))
    }

    func testJSONRoundTrip() throws {
        let expiry = Date(timeIntervalSince1970: 2_000_000_000)
        let original = AuthToken(accessToken: "secret", expiresAt: expiry)
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(AuthToken.self, from: data)
        XCTAssertEqual(decoded, original)
    }

    func testInvalidJSONFailsDecode() {
        let data = Data("{".utf8)
        XCTAssertThrowsError(try JSONDecoder().decode(AuthToken.self, from: data))
    }
}
