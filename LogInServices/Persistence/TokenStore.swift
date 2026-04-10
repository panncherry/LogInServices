//
//  TokenStore.swift
//  LogInServices
//
//  Token persistence behind a protocol. Keychain implementation runs work off the main actor
//  so app launch and login never block UI on secure storage I/O.
//

import Foundation
import Security

public protocol TokenStore: Sendable {
    func save(_ token: AuthToken) async throws
    func load() async throws -> AuthToken?
    func delete() async throws
}

// MARK: - Keychain (production-oriented)

/// Serializes Keychain access through an actor; `SecItem*` APIs are synchronous but fast; we still
/// hop off `@MainActor` via `Task` inside methods so SwiftUI never waits on Keychain during transitions.
public actor KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String

    /// - Parameters:
    ///   - service: Unique service identifier (e.g. bundle ID + suffix).
    ///   - account: Keychain account string for this item.
    public init(service: String, account: String = "authToken") {
        self.service = service
        self.account = account
    }

    public func save(_ token: AuthToken) async throws {
        let service = self.service
        let account = self.account
        try await performKeychainWork {
            let data = try Self.encode(token)
            try Self.saveData(data, service: service, account: account)
        }
    }

    public func load() async throws -> AuthToken? {
        let service = self.service
        let account = self.account
        return try await performKeychainWork {
            Self.loadTokenOrClearIfCorrupted(service: service, account: account)
        }
    }

    public func delete() async throws {
        let service = self.service
        let account = self.account
        try await performKeychainWork {
            Self.deleteItem(service: service, account: account)
        }
    }

    // MARK: - Isolation

    /// Runs Keychain work on an unstructured detached task to avoid blocking the main thread when
    /// callers are on UI isolation.
    private func performKeychainWork<T: Sendable>(_ work: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let value = try work()
                    continuation.resume(returning: value)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Keychain primitives (nonisolated; no shared mutable state)

    nonisolated private static func encode(_ token: AuthToken) throws -> Data {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            return try encoder.encode(token)
        } catch {
            throw AuthError.tokenPersistenceFailed
        }
    }

    nonisolated private static func decode(_ data: Data) throws -> AuthToken {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(AuthToken.self, from: data)
    }

    nonisolated private static func saveData(_ data: Data, service: String, account: String) throws {
        deleteItem(service: service, account: account)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw AuthError.tokenPersistenceFailed
        }
    }

    nonisolated private static func loadData(service: String, account: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return data
    }

    /// Loads and decodes token data. If bytes exist but JSON is invalid, removes the item so we never loop on bad state.
    nonisolated private static func loadTokenOrClearIfCorrupted(service: String, account: String) -> AuthToken? {
        guard let data = loadData(service: service, account: account) else { return nil }
        do {
            return try decode(data)
        } catch {
            deleteItem(service: service, account: account)
            return nil
        }
    }

    nonisolated private static func deleteItem(service: String, account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
