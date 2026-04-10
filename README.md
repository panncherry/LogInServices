# LogInServices

[![Swift](https://img.shields.io/badge/Swift-5-F05138?style=flat&logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-UI-0066CC?style=flat&logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%2F%20macOS-000000?style=flat&logo=apple&logoColor=white)](https://developer.apple.com)
[![Keychain](https://img.shields.io/badge/Keychain-Secure%20token%20storage-5856D6?style=flat&logo=icloud&logoColor=white)](https://developer.apple.com/documentation/security/keychain_services)
[![Concurrency](https://img.shields.io/badge/Concurrency-async%20%2F%20await-F05138?style=flat&logo=swift&logoColor=white)](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
[![XCTest](https://img.shields.io/badge/Tests-XCTest-34C759?style=flat)](https://developer.apple.com/xcode/)

**Highlights:** Authentication · Application security (Keychain, validation) · SwiftUI · Code quality (unit tests, dependency injection, test doubles)

SwiftUI sample app for **email/password authentication**: credential validation, token-based session handling, optional API exchange, and secure token persistence (Keychain via `TokenStore`).

---

## Functionality

| Area | Behavior |
|------|----------|
| **Session flow** | `SessionCoordinator` drives UI phase: bootstrapping → authenticated (`AuthToken`) or unauthenticated. |
| **Login** | Validates email/password, calls `AuthAPIClient`, persists token when valid. |
| **Restore / logout** | Restores session on launch; logout clears stored credentials and returns to unauthenticated. |
| **Validation** | Centralized in `CredentialValidation` with structured errors (`AuthError`). |

---

## Architecture

- **`SessionCoordinator`** (`@MainActor`, `ObservableObject`) — single source of truth for auth phase; SwiftUI-safe updates.
- **`AuthenticationService`** (`Sendable`) — orchestrates validation → network → persistence; async entry points.
- **`AuthAPIClient`** — login transport (replace endpoint/implementation for your backend).
- **`TokenStore`** — token persistence abstraction (Keychain-oriented `KeychainTokenStore` actor).
- **`Clock` / `TimeProvider`** — injectable time for token expiry tests.

---

## Testing & code quality

Unit tests cover tokens, validation, authentication service, session coordinator, and login view model. Test support includes **`InMemoryTokenStore`** and **`TestClock`** for deterministic, isolated tests—no network or Keychain in unit paths unless explicitly testing those layers.

---

## Tech stack

| Area | Details |
|------|---------|
| **Language** | Swift 5 |
| **UI** | SwiftUI |
| **Security** | Keychain Services (actor-isolated store), input validation, structured `AuthError` |
| **Concurrency** | `async`/`await`, `@MainActor` where UI-bound |
| **Quality** | XCTest, protocol-based `TokenStore`, injectable dependencies |

Open `LogInServices.xcodeproj`, select the **LogInServices** scheme, then **Run** (⌘R) or **Test** (⌘U).

---

## Author

**Pann Cherry**
