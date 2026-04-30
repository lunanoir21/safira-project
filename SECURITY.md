# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 1.x.x   | ✅ Yes    |

## Reporting a Vulnerability

**Please do NOT open a public GitHub issue for security vulnerabilities.**

To report a security vulnerability, please email: **security@safira-app.dev**

Include:
- Description of the vulnerability
- Steps to reproduce
- Potential impact
- Any suggested fixes (optional)

We will respond within **48 hours** and aim to release a patch within **7 days** for critical issues.

## Security Architecture

### Encryption
- All vault data is encrypted with **AES-256-GCM** before being written to disk
- The encryption key is **never stored** — it is derived fresh each session from the master password
- **Argon2id** (memory: 64MB, iterations: 3, parallelism: 4) is used for key derivation
- A unique random **salt** (32 bytes) is generated per vault and stored alongside the encrypted data

### Master Password
- The master password is **never stored** in any form
- Only a **verification hash** (Argon2id with separate parameters) is stored to validate unlock
- After 5 failed attempts, the app applies exponential backoff (starting at 2 seconds)

### Biometric Authentication
- Biometric unlock uses the device's secure enclave / TEE
- The session key is wrapped by a biometric-protected key stored in Android Keystore / Linux keyring
- Biometric is an *alternative* unlock path — the master password is always required for first unlock

### Memory Safety
- Sensitive data (keys, passwords) is zeroed from memory immediately after use
- No sensitive data is logged at any log level
- Clipboard is automatically cleared after a configurable delay (default: 30 seconds)

### Network
- All network requests (HaveIBeenPwned) use **k-anonymity** — only the first 5 chars of a SHA-1 hash are sent
- No other network requests are made — the app is fully offline-first

### Data Storage
- All data is stored in an **Isar** database encrypted at the field level
- No cloud sync, no analytics, no telemetry

## Hall of Fame

We appreciate responsible disclosure. Reporters of valid vulnerabilities will be credited here.
