# Safira — Architecture

This document describes the technical architecture of Safira, the decisions behind it, and how the major subsystems interact.

---

## Table of Contents

- [High-Level Overview](#high-level-overview)
- [Layer Architecture](#layer-architecture)
- [Security Architecture](#security-architecture)
- [State Management](#state-management)
- [Routing](#routing)
- [Database](#database)
- [Key Architectural Decisions](#key-architectural-decisions)

---

## High-Level Overview

```
┌─────────────────────────────────────────────────────────┐
│                        SafiraApp                        │
│  (ProviderScope → MaterialApp.router → go_router)       │
└───────────────────────┬─────────────────────────────────┘
                        │
          ┌─────────────▼──────────────┐
          │      Feature Modules        │
          │  auth │ vault │ generator   │
          │  totp │ health│ settings    │
          │  notes│ import/export       │
          └─────────────┬──────────────┘
                        │
          ┌─────────────▼──────────────┐
          │         Core Layer          │
          │  crypto │ kdf │ session     │
          │  router │ theme│ constants  │
          └─────────────┬──────────────┘
                        │
          ┌─────────────▼──────────────┐
          │     Shared / Isar DB        │
          │  models │ providers│widgets │
          └────────────────────────────┘
```

---

## Layer Architecture

Each feature follows **Clean Architecture**:

```
features/<name>/
├── data/
│   ├── repositories/     ← Isar queries, parsers, HIBP API
│   └── parsers/          ← Bitwarden, KeePass import parsers
├── domain/               ← (future) use-cases, pure entities
└── presentation/
    ├── pages/            ← Flutter Widgets (UI only)
    └── providers/        ← Riverpod StateNotifiers
```

**Rules:**
- `presentation/` never imports `data/` directly — goes through a provider.
- `data/` never imports Flutter widgets.
- `core/` has zero feature dependencies.

---

## Security Architecture

### Encryption

```
Master Password
      │
      ▼  Argon2id (64 MB, 3 iter, 4 parallelism)
 Session Key (256-bit, memory only)
      │
      ▼  AES-256-GCM (random 96-bit nonce per encryption)
 EncryptedPayload { ciphertext, nonce, version }
      │
      ▼  stored in Isar
```

- Master password is **never stored** — only the Argon2id verification hash.
- Session key lives **only in RAM** and is zeroed on lock/timeout.
- Every vault field (password, notes, username) is encrypted individually.
- GCM tag provides **authenticated encryption** — tampering is detected.

### Key Derivation Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Algorithm | Argon2id | OWASP recommended; GPU/ASIC resistant |
| Memory | 64 MB | ~100ms on mid-range phone |
| Iterations | 3 | OWASP minimum |
| Parallelism | 4 | Matches typical core count |
| Output | 32 bytes | AES-256 key size |

### Auto-lock

The `SessionManager` starts a countdown timer on every user interaction.  
When the timer fires (default 5 min, configurable), it:
1. Zeroes the session key bytes in memory.
2. Navigates to `LockPage` via `AppRouter`.
3. Clears clipboard if a password was recently copied.

---

## State Management

Safira uses **Riverpod 2.x** with code generation (`riverpod_generator`).

### Provider hierarchy

```
appRouterProvider          ← go_router instance (depends on appStateProvider)
appStateProvider           ← AuthState (locked/unlocked/onboarding)
sessionProvider            ← SessionManager (auto-lock timer)
databaseProvider           ← Isar singleton
vaultProvider              ← VaultNotifier (sealed: Loading/Loaded/Error)
themeModeProvider          ← SafiraThemeMode (light/dark/system)
```

### Sealed state pattern

Every feature notifier uses **sealed classes** for exhaustive state handling:

```dart
sealed class VaultState {}
class VaultLoading extends VaultState {}
class VaultLoaded extends VaultState { final List<VaultEntryModel> entries; }
class VaultError extends VaultState { final String message; }
```

UI switches on `VaultState` with no `else` branch — compiler enforces exhaustiveness.

---

## Routing

`go_router` with **redirect guards**:

```
/onboarding/welcome        → first-run flow
/onboarding/master-password
/onboarding/theme
/onboarding/biometrics
/lock                      → unlock screen (always accessible)
/dashboard                 ← requires unlocked session
/vault/entry/:id
/vault/create
/generator
/totp
/health
/notes
/settings
/import-export
```

The `AppRouter` redirect function:
1. If vault not initialized → force `/onboarding/welcome`
2. If session locked → force `/lock`
3. Otherwise → allow navigation

---

## Database

**Isar** is used as the local encrypted database.

### Schemas

| Collection | Description |
|------------|-------------|
| `VaultEntryModel` | Encrypted credentials (login, card, identity) |
| `VaultMetadataModel` | Argon2id salt, verification hash, settings |
| `AppSettingsModel` | Theme, auto-lock timeout, biometric flag |

### Encryption at rest

Isar itself is not encrypted (no SQLCipher).  
Instead, every sensitive field is individually AES-256-GCM encrypted **before** being written to the database.  
Non-sensitive metadata (entry name, URL for favicon) is stored in plaintext for search performance.

---

## Key Architectural Decisions

### ADR-001: AES-256-GCM over ChaCha20-Poly1305
**Decision:** Use AES-256-GCM.  
**Reason:** Hardware AES acceleration is available on all modern Android devices (ARMv8 AES extension), making it faster than ChaCha20 in practice. GCM also provides authenticated encryption.

### ADR-002: Argon2id over bcrypt/scrypt
**Decision:** Use Argon2id.  
**Reason:** Argon2id is the winner of the Password Hashing Competition and is recommended by OWASP for new applications. It provides both memory-hardness (resists GPU attacks) and side-channel resistance (the `id` variant).

### ADR-003: Riverpod over BLoC
**Decision:** Use Riverpod 2.x with code generation.  
**Reason:** Riverpod eliminates BuildContext dependency for providers, supports compile-time safety, and the `riverpod_generator` reduces boilerplate significantly. BLoC would require more ceremony for the same result.

### ADR-004: Isar over sqflite/Hive
**Decision:** Use Isar.  
**Reason:** Isar provides type-safe queries via code generation, Dart-native async support, and excellent performance on mobile. Hive lacks query support; sqflite requires manual SQL.

### ADR-005: go_router over Navigator 2.0 directly
**Decision:** Use go_router.  
**Reason:** go_router is Flutter team's recommended routing solution, provides declarative URL-based routing, and has first-class deep-link support — essential for future desktop/web expansion.
