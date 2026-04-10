//
//  CredentialValidationTests.swift
//  LogInServicesTests
//

import XCTest
@testable import LogInServices

final class CredentialValidationTests: XCTestCase {
    func testValidCredentials() {
        XCTAssertNil(CredentialValidation.validate(email: "a@b.co", password: "password12"))
    }

    func testEmptyEmail() {
        XCTAssertEqual(CredentialValidation.validate(email: "", password: "password12"), .emptyEmail)
    }

    func testWhitespaceOnlyEmail() {
        XCTAssertEqual(CredentialValidation.validate(email: "   ", password: "password12"), .emptyEmail)
    }

    func testInvalidEmailFormat() {
        XCTAssertEqual(CredentialValidation.validate(email: "not-an-email", password: "password12"), .invalidEmailFormat)
    }

    func testEmptyPassword() {
        XCTAssertEqual(CredentialValidation.validate(email: "a@b.co", password: ""), .emptyPassword)
    }

    func testPasswordTooShort() {
        XCTAssertEqual(
            CredentialValidation.validate(email: "a@b.co", password: "short"),
            .passwordTooShort(minLength: CredentialValidation.minimumPasswordLength)
        )
    }

    func testEmailFormatHelper() {
        XCTAssertTrue(CredentialValidation.isValidEmailFormat("user.name+tag@example.com"))
        XCTAssertFalse(CredentialValidation.isValidEmailFormat("bad"))
    }
}
