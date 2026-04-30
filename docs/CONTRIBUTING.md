# Contributing to Safira

First off — thank you for considering a contribution! 🎉  
Safira is an open-source project and every contribution matters.

---

## Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Project Structure](#project-structure)
- [Submitting Changes](#submitting-changes)
- [Coding Standards](#coding-standards)
- [Security Vulnerabilities](#security-vulnerabilities)

---

## Code of Conduct

Be kind, respectful, and constructive. We follow the [Contributor Covenant](https://www.contributor-covenant.org/version/2/1/code_of_conduct/).

---

## Getting Started

1. **Fork** the repository on GitHub.
2. **Clone** your fork locally:
   ```bash
   git clone https://github.com/<your-username>/safira-project.git
   cd safira-project
   ```
3. Add the upstream remote:
   ```bash
   git remote add upstream https://github.com/lunanoir21/safira-project.git
   ```

---

## Development Setup

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | 3.19+ |
| Dart | 3.3+ |
| Android SDK | API 23+ |
| Linux build tools | clang, cmake, gtk3 |

### Install Flutter dependencies

```bash
flutter pub get
```

### Generate code (Isar schemas + Riverpod providers)

```bash
dart run build_runner build --delete-conflicting-outputs
```

### Run tests

```bash
# Unit tests
flutter test test/unit/

# Integration tests (requires a running device/emulator)
flutter test integration_test/
```

### Run the app

```bash
# Android
flutter run -d android

# Linux
flutter run -d linux
```

---

## Project Structure

```
lib/
├── core/           # App-wide utilities (crypto, theme, router, session)
├── features/       # Feature modules (auth, vault, generator, totp, …)
│   └── <feature>/
│       ├── data/          # Isar repositories, parsers, remote sources
│       ├── domain/        # Entities, use-cases (future)
│       └── presentation/  # Pages, providers (Riverpod)
└── shared/         # Cross-feature widgets, models, providers
```

Each feature follows **Clean Architecture** conventions.  
New features should mirror the existing structure.

---

## Submitting Changes

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/my-awesome-feature
   ```
2. Make your changes and write/update tests.
3. Run the full test suite:
   ```bash
   flutter analyze && flutter test test/unit/
   ```
4. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: add TOTP import via QR scan
   fix: prevent clipboard clear on app resume
   docs: update architecture diagram
   ```
5. Push and open a **Pull Request** against `main`.
6. Fill in the PR template and link any related issues.

---

## Coding Standards

- **Dart style**: Follow `analysis_options.yaml` (strict lints). CI will reject formatting errors.
- **No secrets in code**: Never commit real passwords, API keys, or personal data.
- **Every public API** should have a doc comment (`///`).
- **Security changes** require a more detailed review — tag `@lunanoir21`.
- **Generated files** (`*.g.dart`, `*.freezed.dart`) are not committed — they are regenerated via `build_runner`.

---

## Security Vulnerabilities

Please **do not** open a public issue for security bugs.  
Instead, follow the [Security Policy](../SECURITY.md) and report privately.
