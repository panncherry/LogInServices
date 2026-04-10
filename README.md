# LogInServices

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
- **`TokenStore`** — token persistence abstraction (Keychain-oriented).
- **`Clock` / `TimeProvider`** — injectable time for token expiry tests.

---

## Testing

Unit tests cover tokens, validation, authentication service, session coordinator, and login view model. Test support includes `InMemoryTokenStore` and `TestClock`.

---

## Tech stack

Swift · SwiftUI · Swift Concurrency · XCTest  

Open `LogInServices.xcodeproj`, select the **LogInServices** scheme, then **Run** (⌘R) or **Test** (⌘U).

---

## Author

**Pann Cherry**
