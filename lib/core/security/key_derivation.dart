// lib/core/security/key_derivation.dart
// PRODUCTION — Argon2id key derivation with static API, isolate-based.

import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';
import 'crypto_engine.dart';

// ─── DerivedKeyBundle ────────────────────────────────────────────────────────

/// Material from a single key-derivation call.
class DerivedKeyBundle {
  final Uint8List derivedKey; // 32-byte AES-256 key — keep in memory only
  final Uint8List salt;       // Argon2id salt — safe to persist

  const DerivedKeyBundle({required this.derivedKey, required this.salt});

  /// Zero derived key from memory (call after handing it to SessionManager).
  void zero() => CryptoEngine.zeroMemory(derivedKey);
}

// ─── KeyDerivation ───────────────────────────────────────────────────────────

/// Argon2id-based key derivation for Safira.
///
/// Why Argon2id over PBKDF2/bcrypt:
/// - Memory-hard → GPU/ASIC attacks extremely expensive.
/// - Hybrid of Argon2i (side-channel-resistant) + Argon2d (TMTO-resistant).
/// - Recommended by OWASP, NIST SP 800-132, RFC 9106.
///
/// Default parameters exceed OWASP-recommended minimums:
/// - Memory   : 64 MiB  (OWASP min: 19 MiB)
/// - Iterations: 3      (OWASP min: 1)
/// - Parallelism: 4
/// - Output   : 32 bytes (256-bit)
abstract final class KeyDerivation {
  KeyDerivation._();

  // ── New vault: generate fresh salt + derive key ───────────────────────

  /// Derives a 256-bit AES key from [password] using a freshly generated
  /// random salt. Use when **creating** a new vault.
  static Future<DerivedKeyBundle> deriveKey({
    required String password,
    int memoryKiB = CryptoConstants.argon2MemoryKiB,
    int iterations = CryptoConstants.argon2Iterations,
    int parallelism = CryptoConstants.argon2Parallelism,
  }) async {
    _validate(password);
    final salt =
        CryptoEngine.generateRandomBytes(CryptoConstants.argon2SaltLength);
    final key = await _runInIsolate(
      _IsolateArgs(
        password: password,
        salt: salt,
        memoryKiB: memoryKiB,
        iterations: iterations,
        parallelism: parallelism,
      ),
    );
    return DerivedKeyBundle(derivedKey: key, salt: salt);
  }

  // ── Unlock: re-derive from stored salt ───────────────────────────────

  /// Re-derives the AES key using a **previously stored** [salt].
  /// Use when **unlocking** an existing vault.
  static Future<DerivedKeyBundle> deriveKeyFromSalt({
    required String password,
    required Uint8List salt,
    int memoryKiB = CryptoConstants.argon2MemoryKiB,
    int iterations = CryptoConstants.argon2Iterations,
    int parallelism = CryptoConstants.argon2Parallelism,
  }) async {
    _validate(password);
    final key = await _runInIsolate(
      _IsolateArgs(
        password: password,
        salt: salt,
        memoryKiB: memoryKiB,
        iterations: iterations,
        parallelism: parallelism,
      ),
    );
    return DerivedKeyBundle(derivedKey: key, salt: salt);
  }

  // ── Private ───────────────────────────────────────────────────────────

  static void _validate(String password) {
    if (password.isEmpty) {
      throw const AuthException(message: 'Password cannot be empty.');
    }
    if (password.length > SecurityConstants.maxMasterPasswordLength) {
      throw AuthException(
        message:
            'Password too long (max ${SecurityConstants.maxMasterPasswordLength} chars).',
      );
    }
  }

  static Future<Uint8List> _runInIsolate(_IsolateArgs args) =>
      Isolate.run(() => _deriveSync(args));

  static Uint8List _deriveSync(_IsolateArgs args) {
    try {
      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        args.salt,
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: args.iterations,
        memoryPowerOf2: _memKiBToPower(args.memoryKiB),
        lanes: args.parallelism,
        desiredKeyLength: CryptoConstants.argon2KeyLength,
      );

      final gen = Argon2BytesGenerator()..init(parameters);
      final pwBytes = Uint8List.fromList(utf8.encode(args.password));
      final out = Uint8List(CryptoConstants.argon2KeyLength);
      gen.generateBytes(pwBytes, out);

      // Zero password bytes from isolate memory.
      CryptoEngine.zeroMemory(pwBytes);

      return out;
    } on Object catch (e) {
      throw CryptoException(message: 'Argon2id failed: $e', cause: e);
    }
  }

  /// Converts a KiB value to the nearest power-of-2 exponent.
  static int _memKiBToPower(int kib) {
    if (kib <= 0) return 16; // default: 2^16 = 65536 KiB = 64 MiB
    var p = 0;
    var v = kib;
    while (v > 1) {
      v >>= 1;
      p++;
    }
    return p;
  }
}

// ─── Internal args record ─────────────────────────────────────────────────────

class _IsolateArgs {
  final String password;
  final Uint8List salt;
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  const _IsolateArgs({
    required this.password,
    required this.salt,
    required this.memoryKiB,
    required this.iterations,
    required this.parallelism,
  });
}
