//
//  CredentialValidation.swift
//  LogInServices
//
//  Pure validation helpers — easy to unit test without UI or I/O.
//

import Foundation

public enum CredentialValidation {
    public static let minimumPasswordLength = 8

    /// Returns the first validation failure, or `nil` if input is acceptable for submission.
    public static func validate(email: String, password: String) -> CredentialValidationError? {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedEmail.isEmpty { return .emptyEmail }
        if isValidEmailFormat(trimmedEmail) == false { return .invalidEmailFormat }
        if password.isEmpty { return .emptyPassword }
        if password.count < minimumPasswordLength { return .passwordTooShort(minLength: minimumPasswordLength) }
        return nil
    }

    /// Lightweight RFC-inspired check; not a substitute for server-side validation.
    public static func isValidEmailFormat(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return false }
        let range = NSRange(email.startIndex..., in: email)
        return regex.firstMatch(in: email, options: [], range: range) != nil
    }
}
