//
//  Clock.swift
//  LogInServices
//
//  Injectable time source for testable expiration logic. Production uses wall clock;
//  tests inject a fixed or advancing clock.
//

import Foundation

/// Wall-clock time provider. Kept as a protocol (not `Clock` from Swift Concurrency) to avoid
/// confusion with `Swift.Clock` and to keep the surface area minimal for auth.
public protocol TimeProvider: Sendable {
    func now() -> Date
}

public struct SystemTimeProvider: TimeProvider {
    public init() {}

    public func now() -> Date {
        Date()
    }
}
