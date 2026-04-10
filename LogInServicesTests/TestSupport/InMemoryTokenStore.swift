//
//  InMemoryTokenStore.swift
//  LogInServicesTests
//

import Foundation
@testable import LogInServices

actor InMemoryTokenStore: TokenStore {
    private(set) var stored: AuthToken?
    private var failSave = false
    private var failDelete = false
    private var failLoad = false

    func setFailSave(_ value: Bool) {
        failSave = value
    }

    func setFailLoad(_ value: Bool) {
        failLoad = value
    }

    func setFailDelete(_ value: Bool) {
        failDelete = value
    }

    func save(_ token: AuthToken) async throws {
        if failSave { throw AuthError.tokenPersistenceFailed }
        stored = token
    }

    func load() async throws -> AuthToken? {
        if failLoad { throw AuthError.tokenPersistenceFailed }
        return stored
    }

    func delete() async throws {
        if failDelete { throw AuthError.tokenPersistenceFailed }
        stored = nil
    }
}
