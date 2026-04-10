//
//  TestClock.swift
//  LogInServicesTests
//

import Foundation
@testable import LogInServices

/// Mutable clock for deterministic expiry tests (no `sleep`).
final class TestClock: TimeProvider, @unchecked Sendable {
    private var current: Date

    init(_ date: Date = Date(timeIntervalSince1970: 1_700_000_000)) {
        self.current = date
    }

    func set(_ date: Date) {
        current = date
    }

    func advance(by interval: TimeInterval) {
        current = current.addingTimeInterval(interval)
    }

    func now() -> Date {
        current
    }
}
