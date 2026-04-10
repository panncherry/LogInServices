//
//  AuthAPIClient.swift
//  LogInServices
//
//  Abstraction over remote login. `MockAuthAPIClient` simulates success, bad credentials,
//  and transport failures for development and tests. Swap for a real URLSession implementation in production.
//

import Foundation

public struct LoginRequest: Sendable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

/// Production-shaped API boundary: async login that returns a fresh `AuthToken` from the server.
public protocol AuthAPIClient: Sendable {
    func login(_ request: LoginRequest) async throws -> AuthToken
}

// MARK: - Mock (demo / tests)

/// Simulates a backend: accepts fixed credentials, returns a token with a finite lifetime.
/// Does not persist credentials; passwords exist only for the duration of the `login` call.
public struct MockAuthAPIClient: AuthAPIClient {
    public enum FailureMode: Sendable {
        case none
        case invalidCredentials
        case network
        case server(status: Int)
    }

    private let timeProvider: TimeProvider
    private let tokenLifetime: TimeInterval
    private let validEmail: String
    private let validPassword: String
    public var failureMode: FailureMode
    /// Set to `0` in unit tests to avoid artificial delay; UI uses a small value to feel responsive.
    public var loginDelayNanoseconds: UInt64

    public init(
        timeProvider: TimeProvider = SystemTimeProvider(),
        tokenLifetime: TimeInterval = 3600,
        validEmail: String = "user@example.com",
        validPassword: String = "password123",
        failureMode: FailureMode = .none,
        loginDelayNanoseconds: UInt64 = 15_000_000
    ) {
        self.timeProvider = timeProvider
        self.tokenLifetime = tokenLifetime
        self.validEmail = validEmail
        self.validPassword = validPassword
        self.failureMode = failureMode
        self.loginDelayNanoseconds = loginDelayNanoseconds
    }

    public func login(_ request: LoginRequest) async throws -> AuthToken {
        if loginDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: loginDelayNanoseconds)
        }

        switch failureMode {
        case .none:
            break
        case .invalidCredentials:
            throw AuthError.invalidCredentials
        case .network:
            throw AuthError.networkUnavailable
        case .server(let status):
            throw AuthError.serverError(code: status)
        }

        guard request.email == validEmail, request.password == validPassword else {
            throw AuthError.invalidCredentials
        }

        let now = timeProvider.now()
        let tokenValue = "mock-access-token-\(UUID().uuidString)"
        return AuthToken(accessToken: tokenValue, expiresAt: now.addingTimeInterval(tokenLifetime))
    }
}
