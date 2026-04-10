//
//  AuthError.swift
//  LogInServices
//
//  Typed errors for auth, storage, and validation. User-facing copy is sanitized; debug descriptions
//  may carry more detail for logging (still never include secrets).
//

import Foundation

public enum AuthError: Error, Equatable, Sendable {
    case invalidCredentials
    case networkUnavailable
    case serverError(code: Int)
    case tokenExpired
    case tokenCorrupted
    case tokenPersistenceFailed
    case validation(CredentialValidationError)
    case unexpectedUnderlying(String)

    /// Safe message for UI and analytics (no tokens, passwords, or stack traces).
    public var userFacingMessage: String {
        switch self {
        case .invalidCredentials:
            return "Email or password is incorrect."
        case .networkUnavailable:
            return "Check your connection and try again."
        case .serverError:
            return "Something went wrong. Please try again later."
        case .tokenExpired:
            return "Your session expired. Please sign in again."
        case .tokenCorrupted:
            return "Your saved session could not be read. Please sign in again."
        case .tokenPersistenceFailed:
            return "Could not save your session securely. Please try again."
        case .validation(let v):
            return v.userFacingMessage
        case .unexpectedUnderlying:
            return "Something went wrong. Please try again."
        }
    }

    /// Debug-only detail; avoid showing raw `unexpectedUnderlying` to users.
    public var debugDescription: String {
        switch self {
        case .invalidCredentials:
            return "invalidCredentials"
        case .networkUnavailable:
            return "networkUnavailable"
        case .serverError(let code):
            return "serverError(\(code))"
        case .tokenExpired:
            return "tokenExpired"
        case .tokenCorrupted:
            return "tokenCorrupted"
        case .tokenPersistenceFailed:
            return "tokenPersistenceFailed"
        case .validation(let v):
            return "validation(\(v))"
        case .unexpectedUnderlying(let s):
            return "unexpectedUnderlying(\(s))"
        }
    }
}

public enum CredentialValidationError: Error, Equatable, Sendable {
    case emptyEmail
    case invalidEmailFormat
    case emptyPassword
    case passwordTooShort(minLength: Int)

    public var userFacingMessage: String {
        switch self {
        case .emptyEmail:
            return "Enter your email address."
        case .invalidEmailFormat:
            return "Enter a valid email address."
        case .emptyPassword:
            return "Enter your password."
        case .passwordTooShort(let min):
            return "Password must be at least \(min) characters."
        }
    }
}
