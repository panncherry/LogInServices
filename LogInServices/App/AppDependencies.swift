//
//  AppDependencies.swift
//  LogInServices
//
//  Composition root: wires concrete implementations. Replace `MockAuthAPIClient` with a real
//  `URLSession`-based `AuthAPIClient` for production.
//

import Foundation

public enum AppDependencies {
    public static let defaultKeychainService = "com.panncherry.weebly.LogInServices.auth"

    @MainActor
    public static func makeSessionCoordinator(
        api: AuthAPIClient = MockAuthAPIClient(),
        tokenStore: TokenStore = KeychainTokenStore(service: defaultKeychainService),
        timeProvider: TimeProvider = SystemTimeProvider()
    ) -> SessionCoordinator {
        let authService = AuthenticationService(api: api, tokenStore: tokenStore, timeProvider: timeProvider)
        return SessionCoordinator(authenticationService: authService)
    }
}
