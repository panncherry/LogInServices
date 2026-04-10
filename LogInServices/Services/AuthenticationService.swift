//
//  AuthenticationService.swift
//  LogInServices
//
//  Stateless orchestration: validate → network → persist. All entry points are async;
//  callers on the main actor await results without blocking UI because stores and API hop work
//  off the main thread internally.
//

import Foundation

public struct AuthenticationService: Sendable {
    private let api: AuthAPIClient
    private let tokenStore: TokenStore
    private let timeProvider: TimeProvider

    public init(api: AuthAPIClient, tokenStore: TokenStore, timeProvider: TimeProvider) {
        self.api = api
        self.tokenStore = tokenStore
        self.timeProvider = timeProvider
    }

    /// Validates input, exchanges credentials for a token, and persists it. Throws on validation or transport errors.
    public func login(email: String, password: String) async throws -> AuthToken {
        if let validationError = CredentialValidation.validate(email: email, password: password) {
            throw AuthError.validation(validationError)
        }
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let request = LoginRequest(email: trimmedEmail, password: password)
        let token: AuthToken
        do {
            token = try await api.login(request)
        } catch let auth as AuthError {
            throw auth
        } catch {
            throw AuthError.unexpectedUnderlying(String(describing: type(of: error)))
        }

        let now = timeProvider.now()
        guard token.isValid(at: now) else {
            throw AuthError.tokenExpired
        }

        do {
            try await tokenStore.save(token)
        } catch let auth as AuthError {
            throw auth
        } catch {
            throw AuthError.tokenPersistenceFailed
        }
        return token
    }

    /// Loads persisted token and checks expiry. Returns `nil` if missing, expired, or unreadable (store self-heals).
    public func restoreSession() async -> AuthToken? {
        let token: AuthToken?
        do {
            token = try await tokenStore.load()
        } catch {
            return nil
        }
        guard let token else { return nil }
        let now = timeProvider.now()
        guard token.isValid(at: now) else {
            await logoutBestEffort()
            return nil
        }
        return token
    }

    /// Removes persisted credentials. Safe to call multiple times.
    public func logout() async {
        await logoutBestEffort()
    }

    private func logoutBestEffort() async {
        do {
            try await tokenStore.delete()
        } catch {
            // Intentionally ignore: user must still be signed out in memory even if Keychain fails.
        }
    }
}
