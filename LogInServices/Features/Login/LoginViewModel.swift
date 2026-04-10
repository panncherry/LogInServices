//
//  LoginViewModel.swift
//  LogInServices
//
//  Form state and loading/error presentation. Stays `@MainActor` because it drives SwiftUI;
//  session work is async and does not block the main thread.
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    func signIn(session: SessionCoordinator) async {
        errorMessage = nil
        isLoading = true
        defer { isLoading = false }
        do {
            try await session.login(email: email, password: password)
        } catch let error as AuthError {
            errorMessage = error.userFacingMessage
        } catch {
            errorMessage = AuthError.unexpectedUnderlying("login").userFacingMessage
        }
    }
}
