//
//  AuthenticationServiceTests.swift
//  LogInServicesTests
//

import XCTest
@testable import LogInServices

final class AuthenticationServiceTests: XCTestCase {
    private func makeService(
        api: MockAuthAPIClient,
        store: InMemoryTokenStore = InMemoryTokenStore(),
        clock: TestClock = TestClock()
    ) -> (AuthenticationService, InMemoryTokenStore, TestClock) {
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)
        return (service, store, clock)
    }

    func testLoginSuccessPersistsToken() async throws {
        let clock = TestClock(Date(timeIntervalSince1970: 2_000_000_000))
        let api = MockAuthAPIClient(timeProvider: clock, loginDelayNanoseconds: 0)
        let (service, store, _) = makeService(api: api, clock: clock)

        let token = try await service.login(email: "user@example.com", password: "password123")
        XCTAssertTrue(token.isValid(at: clock.now()))
        let stored = await store.stored
        XCTAssertEqual(stored, token)
    }

    func testLoginValidationFailure() async {
        let api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        let (service, store, _) = makeService(api: api)

        do {
            _ = try await service.login(email: "", password: "password123")
            XCTFail("Expected validation error")
        } catch let error as AuthError {
            if case .validation(let v) = error {
                XCTAssertEqual(v, .emptyEmail)
            } else {
                XCTFail("Wrong error \(error)")
            }
        } catch {
            XCTFail("Unexpected \(error)")
        }
        let stored = await store.stored
        XCTAssertNil(stored)
    }

    func testLoginInvalidCredentials() async {
        let api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        let (service, store, _) = makeService(api: api)

        do {
            _ = try await service.login(email: "user@example.com", password: "notpassword123")
            XCTFail("Expected invalid credentials")
        } catch let error as AuthError {
            XCTAssertEqual(error, .invalidCredentials)
        } catch {
            XCTFail("Unexpected \(error)")
        }
        let persisted = await store.stored
        XCTAssertNil(persisted)
    }

    func testLoginNetworkFailure() async {
        var api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        api.failureMode = .network
        let (service, store, _) = makeService(api: api)

        do {
            _ = try await service.login(email: "user@example.com", password: "password123")
            XCTFail("Expected network error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .networkUnavailable)
        } catch {
            XCTFail("Unexpected \(error)")
        }
        let persisted = await store.stored
        XCTAssertNil(persisted)
    }

    func testLoginPersistenceFailure() async {
        let api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        let store = InMemoryTokenStore()
        await store.setFailSave(true)
        let clock = TestClock()
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)

        do {
            _ = try await service.login(email: "user@example.com", password: "password123")
            XCTFail("Expected persistence error")
        } catch let error as AuthError {
            XCTAssertEqual(error, .tokenPersistenceFailed)
        } catch {
            XCTFail("Unexpected \(error)")
        }
    }

    func testRestoreNilWhenNoToken() async {
        let api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        let (service, _, _) = makeService(api: api)
        let restored = await service.restoreSession()
        XCTAssertNil(restored)
    }

    func testRestoreValidToken() async throws {
        let clock = TestClock(Date(timeIntervalSince1970: 2_000_000_000))
        let token = AuthToken(accessToken: "t", expiresAt: clock.now().addingTimeInterval(3600))
        let store = InMemoryTokenStore()
        try await store.save(token)
        let api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)

        let restored = await service.restoreSession()
        XCTAssertEqual(restored, token)
    }

    func testRestoreExpiredTokenClears() async throws {
        let clock = TestClock(Date(timeIntervalSince1970: 2_000_000_000))
        let token = AuthToken(accessToken: "t", expiresAt: clock.now().addingTimeInterval(-10))
        let store = InMemoryTokenStore()
        try await store.save(token)
        let api = MockAuthAPIClient(loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)

        let restored = await service.restoreSession()
        XCTAssertNil(restored)
        let persisted = await store.stored
        XCTAssertNil(persisted)
    }

    func testLogoutClearsStore() async throws {
        let clock = TestClock()
        let token = AuthToken(accessToken: "t", expiresAt: clock.now().addingTimeInterval(3600))
        let store = InMemoryTokenStore()
        try await store.save(token)
        let service = AuthenticationService(api: MockAuthAPIClient(loginDelayNanoseconds: 0), tokenStore: store, timeProvider: clock)

        await service.logout()
        let persisted = await store.stored
        XCTAssertNil(persisted)
    }
}
