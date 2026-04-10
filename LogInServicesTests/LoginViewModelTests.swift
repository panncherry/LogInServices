//
//  LoginViewModelTests.swift
//  LogInServicesTests
//

import XCTest
@testable import LogInServices

@MainActor
final class LoginViewModelTests: XCTestCase {
    private func makeCoordinator() async -> SessionCoordinator {
        let clock = TestClock()
        let store = InMemoryTokenStore()
        let api = MockAuthAPIClient(timeProvider: clock, loginDelayNanoseconds: 0)
        let service = AuthenticationService(api: api, tokenStore: store, timeProvider: clock)
        let coordinator = SessionCoordinator(authenticationService: service)
        await coordinator.restoreSessionOnLaunch()
        return coordinator
    }

    func testSignInSetsValidationErrorMessage() async {
        let coordinator = await makeCoordinator()
        let vm = LoginViewModel()
        vm.email = ""
        vm.password = "password123"

        await vm.signIn(session: coordinator)
        XCTAssertEqual(vm.errorMessage, CredentialValidationError.emptyEmail.userFacingMessage)
        guard case .unauthenticated = coordinator.phase else {
            XCTFail("Should stay logged out")
            return
        }
    }

    func testSignInSuccessClearsError() async {
        let coordinator = await makeCoordinator()
        let vm = LoginViewModel()
        vm.email = "user@example.com"
        vm.password = "password123"

        await vm.signIn(session: coordinator)
        XCTAssertNil(vm.errorMessage)
        guard case .authenticated = coordinator.phase else {
            XCTFail("Expected authenticated")
            return
        }
    }

    func testSignInInvalidCredentials() async {
        let coordinator = await makeCoordinator()
        let vm = LoginViewModel()
        vm.email = "user@example.com"
        vm.password = "notpassword123"

        await vm.signIn(session: coordinator)
        XCTAssertEqual(vm.errorMessage, AuthError.invalidCredentials.userFacingMessage)
    }
}
