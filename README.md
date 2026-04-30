# 🔐 Safira — Open Source Password Manager

<div align="center">

[![Flutter](https://img.shields.io/badge/Flutter-3.19+-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.3+-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)](LICENSE)
[![CI/CD](https://img.shields.io/github/actions/workflow/status/lunanoir21/safira-project/ci.yml?style=for-the-badge&label=CI%2FCD)](https://github.com/lunanoir21/safira-project/actions)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Linux-lightgrey?style=for-the-badge)](https://github.com/lunanoir21/safira-project)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen?style=for-the-badge)](docs/CONTRIBUTING.md)

**A modern, secure, offline-first password manager built with Flutter.**

*Military-grade AES-256-GCM encryption • Argon2id key derivation • Zero-knowledge architecture*

</div>

---

## ✨ Features

### 🔐 Security First
- **AES-256-GCM** authenticated encryption for all vault data
- **Argon2id** memory-hard key derivation — master password never stored
- **TOTP/2FA** authenticator built-in (RFC 6238 compliant)
- **Biometric authentication** (fingerprint / face unlock)
- **Auto-lock** with configurable session timeout
- **Clipboard auto-clear** after configurable delay (default 30s)
- **Brute-force protection** with exponential backoff
- **Password health checker** + HaveIBeenPwned k-anonymity API
- **Zero-knowledge** — no data ever leaves your device

### 🗄️ Vault
- Unlimited encrypted password entries
- Custom fields (URL, username, password, notes, TOTP)
- Categories, tags, and favorites system
- Full-text fuzzy search across all fields
- Secure notes with encrypted file attachments
- Complete password history tracking
- Trash / soft-delete with recovery

### 🔧 Built-in Tools
- **Advanced password generator** — length, charset, rules, pronounceable
- **TOTP authenticator** — scan QR or enter secret manually
- **Password strength analyzer** — entropy-based real-time scoring
- **Breach checker** — HaveIBeenPwned via k-anonymity (privacy-safe)
- **Import/Export** — Bitwarden, 1Password, KeePass, CSV formats

### 🎨 UI/UX Excellence
- **Material 3** with dynamic color theming
- Light / Dark / System / Custom themes
- Smooth animated onboarding flow
- Responsive layout — mobile & desktop
- Linux keyboard shortcuts & window resizing
- Accessibility-first design (screen reader support)

### 🚀 CI/CD
- Automated APK & Linux binary via GitHub Actions
- Automatic GitHub Releases on version tag push

---

## 📦 Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter 3.19+ / Dart 3.3+ |
| State Management | Riverpod 2.x + riverpod_generator |
| Local Database | Isar (native, encrypted) |
| Encryption | AES-256-GCM (pointycastle + cryptography) |
| Key Derivation | Argon2id |
| Routing | go_router |
| Code Gen | freezed + json_serializable |
| Testing | flutter_test + integration_test + mocktail |

---

## 🏗️ Clean Architecture

```
lib/
├── main.dart                    # Entry point
├── app.dart                     # Root widget
├── core/
│   ├── constants/               # App-wide constants
│   ├── errors/                  # Failures & exceptions
│   ├── extensions/              # Dart/Flutter extensions
│   ├── security/                # Crypto engine (AES, Argon2, TOTP)
│   ├── session/                 # Auto-lock & session management
│   ├── router/                  # go_router configuration
│   └── theme/                   # Material 3 theme system
├── features/
│   ├── onboarding/              # Animated welcome + setup flow
│   ├── auth/                    # Master password + biometric
│   ├── vault/                   # Password CRUD & search
│   ├── generator/               # Password generator
│   ├── totp/                    # TOTP authenticator
│   ├── health/                  # Password health & breach check
│   ├── secure_notes/            # Encrypted notes + attachments
│   ├── import_export/           # Format converters
│   └── settings/                # App preferences
└── shared/
    ├── widgets/                 # Reusable UI components
    ├── models/                  # Isar data models
    └── providers/               # Global Riverpod providers

# Each feature follows Clean Architecture:
feature/
├── data/
│   ├── datasources/             # Isar / secure storage
│   ├── models/                  # Data models (Isar entities)
│   └── repositories/            # Repository implementations
├── domain/
│   ├── entities/                # Pure domain entities
│   ├── repositories/            # Abstract repository interfaces
│   └── usecases/                # Business logic use cases
└── presentation/
    ├── pages/                   # Full-screen pages
    ├── widgets/                 # Feature-specific widgets
    └── providers/               # Riverpod providers
```

---

## 🚀 Getting Started

### Prerequisites

```bash
flutter --version   # >= 3.19.0
dart --version      # >= 3.3.0
```

For Linux builds:
```bash
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev
```

### Installation

```bash
git clone https://github.com/lunanoir21/safira-project.git
cd safira-project
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Run

```bash
flutter run                          # Default device
flutter run -d linux                 # Linux desktop
flutter run -d android               # Android
```

### Test

```bash
flutter test test/unit/              # Unit tests
flutter test integration_test/       # Integration tests
flutter test --coverage              # With coverage report
genhtml coverage/lcov.info -o coverage/html  # HTML report
```

### Build

```bash
# Android
flutter build apk --release --obfuscate --split-debug-info=build/debug-info
flutter build appbundle --release

# Linux
flutter build linux --release
```

---

## 🤝 Contributing

We welcome contributions! See [CONTRIBUTING.md](docs/CONTRIBUTING.md).

1. Fork the repository
2. Create your feature branch: `git checkout -b feat/amazing-feature`
3. Commit using conventional commits: `git commit -m 'feat: add amazing feature'`
4. Push: `git push origin feat/amazing-feature`
5. Open a Pull Request

---

## 🔒 Security

Found a vulnerability? See [SECURITY.md](SECURITY.md) for responsible disclosure.

**Never** open a public issue for security vulnerabilities.

---

## 📄 License

[MIT License](LICENSE) © 2024 lunanoir21
