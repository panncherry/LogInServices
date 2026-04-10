//
//  SessionCoordinator.swift
//  LogInServices
//
//  Single UI-facing source of truth for auth phase. Marked `@MainActor` so SwiftUI bindings and
//  `ObservableObject` updates stay on the main thread; async work is awaited from methods without blocking.
//

import Combine
import Foundation
import SwiftUI

@MainActor
public final class SessionCoordinator: ObservableObject {
    public enum Phase: Equatable {
        case bootstrapping
        case unauthenticated
        case authenticated(AuthToken)
    }

    @Published public private(set) var phase: Phase = .bootstrapping

    private let authenticationService: AuthenticationService

    public init(authenticationService: AuthenticationService) {
        self.authenticationService = authenticationService
    }

    /// Call on launch before rendering login vs home. Transitions: bootstrapping → authenticated | unauthenticated.
    public func restoreSessionOnLaunch() async {
        phase = .bootstrapping
        if let token = await authenticationService.restoreSession() {
            phase = .authenticated(token)
        } else {
            phase = .unauthenticated
        }
    }

    public func login(email: String, password: String) async throws {
        let token = try await authenticationService.login(email: email, password: password)
        phase = .authenticated(token)
    }

    public func logout() async {
        await authenticationService.logout()
        phase = .unauthenticated
    }
}
