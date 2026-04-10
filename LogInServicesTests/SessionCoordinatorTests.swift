//
//  SessionCoordinatorTests.swift
//  LogInServicesTests
//

import XCTest
@testable import LogInServices

@MainActor
final class SessionCoordinatorTests: XCTestCase {
    func testLaunchRestoreUnauthenticated() async {
        let clock = TestClock()
        let store = InMemoryTokenStore()
        let api = MockAuthAPIClient(timeProvider: clock, loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)
        let coordinator = SessionCoordinator(authenticationService: service)

        await coordinator.restoreSessionOnLaunch()
        guard case .unauthenticated = coordinator.phase else {
            XCTFail("Expected unauthenticated")
            return
        }
    }

    func testLaunchRestoreAuthenticated() async throws {
        let clock = TestClock(Date(timeIntervalSince1970: 2_000_000_000))
        let token = AuthToken(accessToken: "t", expiresAt: clock.now().addingTimeInterval(3600))
        let store = InMemoryTokenStore()
        try await store.save(token)
        let api = MockAuthAPIClient(timeProvider: clock, loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)
        let coordinator = SessionCoordinator(authenticationService: service)

        await coordinator.restoreSessionOnLaunch()
        guard case .authenticated(let restored) = coordinator.phase else {
            XCTFail("Expected authenticated")
            return
        }
        XCTAssertEqual(restored, token)
    }

    func testLoginUpdatesPhase() async throws {
        let clock = TestClock()
        let store = InMemoryTokenStore()
        let api = MockAuthAPIClient(timeProvider: clock, loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)
        let coordinator = SessionCoordinator(authenticationService: service)

        await coordinator.restoreSessionOnLaunch()
        try await coordinator.login(email: "user@example.com", password: "password123")
        guard case .authenticated = coordinator.phase else {
            XCTFail("Expected authenticated")
            return
        }
    }

    func testLogout() async throws {
        let clock = TestClock()
        let token = AuthToken(accessToken: "t", expiresAt: clock.now().addingTimeInterval(3600))
        let store = InMemoryTokenStore()
        try await store.save(token)
        let api = MockAuthAPIClient(timeProvider: clock, loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)
        let coordinator = SessionCoordinator(authenticationService: service)

        await coordinator.restoreSessionOnLaunch()
        await coordinator.logout()
        guard case .unauthenticated = coordinator.phase else {
            XCTFail("Expected unauthenticated after logout")
            return
        }
        let persisted = await store.stored
        XCTAssertNil(persisted)
    }
}
