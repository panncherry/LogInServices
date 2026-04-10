//
//  AuthToken.swift
//  LogInServices
//
//  Single source of truth for persisted session credentials. Validity is evaluated against
//  an injectable `Date` so tests can simulate expiry without waiting.
//
//  `Codable` is implemented in a `nonisolated` extension so JSON encoding/decoding can run
//  from Keychain helpers off the main actor when the module uses default MainActor isolation.
//

import Foundation

public struct AuthToken: Equatable, Sendable {
    /// Opaque bearer value. Never log or persist outside the Keychain-backed store.
    public let accessToken: String
    /// Absolute expiration instant in the app's reference frame (server-provided or derived from `expiresIn`).
    public let expiresAt: Date

    public init(accessToken: String, expiresAt: Date) {
        self.accessToken = accessToken
        self.expiresAt = expiresAt
    }

    /// Returns whether the token may be used for authenticated API calls at `referenceDate`.
    /// - Parameters:
    ///   - referenceDate: Typically `timeProvider.now()`; inject fixed dates in tests.
    ///   - leeway: Subtract from effective expiry to avoid using tokens that are about to expire (clock skew).
    nonisolated public func isValid(at referenceDate: Date, leeway: TimeInterval = 60) -> Bool {
        guard accessToken.isEmpty == false else { return false }
        return referenceDate.addingTimeInterval(leeway) < expiresAt
    }
}

extension AuthToken: Codable {
    nonisolated public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let accessToken = try c.decode(String.self, forKey: .accessToken)
        let expiresAt = try c.decode(Date.self, forKey: .expiresAt)
        self.init(accessToken: accessToken, expiresAt: expiresAt)
    }

    nonisolated public func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(accessToken, forKey: .accessToken)
        try c.encode(expiresAt, forKey: .expiresAt)
    }

    enum CodingKeys: String, CodingKey {
        case accessToken
        case expiresAt
    }
}
