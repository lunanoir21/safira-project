import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:argon2/argon2.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/errors/exceptions.dart';
import 'package:safira/core/security/crypto_engine.dart';

/// Argon2id-based key derivation for Safira.
///
/// Argon2id is the winner of the Password Hashing Competition (PHC) and
/// is recommended by OWASP, NIST, and RFC 9106 for password hashing.
///
/// Why Argon2id over PBKDF2/bcrypt:
/// - Memory-hard: GPU/ASIC attacks are extremely expensive
/// - Side-channel resistant (hybrid of Argon2i + Argon2d)
/// - Configurable memory, time, and parallelism costs
///
/// Parameters used (OWASP recommended minimums exceeded):
/// - Memory: 64 MB
/// - Iterations: 3
/// - Parallelism: 4
/// - Output length: 32 bytes (256-bit AES key)
final class KeyDerivation {
  KeyDerivation._();

  static final KeyDerivation instance = KeyDerivation._();

  /// Derives a 256-bit encryption key from [masterPassword] and [salt].
  ///
  /// This is a CPU and memory intensive operation — always call in an isolate
  /// to avoid blocking the UI thread.
  ///
  /// Returns the derived key as a [Uint8List].
  Future<Uint8List> deriveKey({
    required String masterPassword,
    required Uint8List salt,
  }) async {
    _validatePassword(masterPassword);

    // Run Argon2id in an isolate to avoid blocking the UI thread
    return Isolate.run(
      () => _deriveKeySync(masterPassword, salt),
    );
  }

  /// Derives both an encryption key and a verification hash from the master password.
  ///
  /// Uses separate salts for key derivation and verification hash to ensure
  /// they are cryptographically independent.
  Future<DerivedKeyBundle> deriveKeyBundle({
    required String masterPassword,
  }) async {
    _validatePassword(masterPassword);

    final keySalt = CryptoEngine.generateRandomBytes(CryptoConstants.argon2SaltLength);
    final verificationSalt = CryptoEngine.generateRandomBytes(CryptoConstants.argon2SaltLength);

    final results = await Future.wait([
      deriveKey(masterPassword: masterPassword, salt: keySalt),
      _deriveVerificationHash(masterPassword: masterPassword, salt: verificationSalt),
    ]);

    return DerivedKeyBundle(
      encryptionKey: results[0],
      keySalt: keySalt,
      verificationHash: results[1],
      verificationSalt: verificationSalt,
    );
  }

  /// Verifies that [masterPassword] matches the stored [verificationHash].
  ///
  /// Uses constant-time comparison to prevent timing attacks.
  Future<bool> verifyPassword({
    required String masterPassword,
    required Uint8List verificationHash,
    required Uint8List verificationSalt,
  }) async {
    try {
      _validatePassword(masterPassword);

      final candidateHash = await _deriveVerificationHash(
        masterPassword: masterPassword,
        salt: verificationSalt,
      );

      return CryptoEngine.constantTimeEquals(candidateHash, verificationHash);
    } on AuthException {
      rethrow;
    } on Object catch (e) {
      throw AuthException(
        message: 'Password verification failed',
        cause: e,
      );
    }
  }

  /// Re-derives the encryption key from password + stored salt (for unlock).
  Future<Uint8List> rederiveKey({
    required String masterPassword,
    required Uint8List keySalt,
  }) =>
      deriveKey(masterPassword: masterPassword, salt: keySalt);

  // ─── Private ──────────────────────────────────────────────────────────────

  static Uint8List _deriveKeySync(String password, Uint8List salt) {
    try {
      final parameters = Argon2Parameters(
        Argon2Parameters.ARGON2_id,
        salt,
        version: Argon2Parameters.ARGON2_VERSION_13,
        iterations: CryptoConstants.argon2Iterations,
        memoryPowerOf2: 16, // 2^16 = 65536 KB = 64 MB
        lanes: CryptoConstants.argon2Parallelism,
        desiredKeyLength: CryptoConstants.argon2KeyLength,
      );

      final generator = Argon2BytesGenerator()..init(parameters);
      final passwordBytes = Uint8List.fromList(utf8.encode(password));
      final result = Uint8List(CryptoConstants.argon2KeyLength);
      generator.generateBytes(passwordBytes, result);

      // Zero out password bytes from memory
      CryptoEngine.zeroMemory(passwordBytes);

      return result;
    } on Object catch (e) {
      throw CryptoException(
        message: 'Argon2id key derivation failed',
        cause: e,
      );
    }
  }

  Future<Uint8List> _deriveVerificationHash({
    required String masterPassword,
    required Uint8List salt,
  }) =>
      Isolate.run(() => _deriveKeySync(masterPassword, salt));

  void _validatePassword(String password) {
    if (password.length < CryptoConstants.argon2KeyLength ~/ 4) {
      throw AuthException(
        message: 'Master password too short',
      );
    }
    if (password.length > SecurityConstants.maxMasterPasswordLength) {
      throw AuthException(
        message: 'Master password too long (max ${SecurityConstants.maxMasterPasswordLength} chars)',
      );
    }
  }
}

/// Bundle containing all derived key material for a new vault.
final class DerivedKeyBundle {
  const DerivedKeyBundle({
    required this.encryptionKey,
    required this.keySalt,
    required this.verificationHash,
    required this.verificationSalt,
  });

  /// The AES-256 encryption key (keep in memory only, never persist)
  final Uint8List encryptionKey;

  /// Salt used to derive [encryptionKey] (safe to store)
  final Uint8List keySalt;

  /// Hash used to verify master password (safe to store)
  final Uint8List verificationHash;

  /// Salt used to derive [verificationHash] (safe to store)
  final Uint8List verificationSalt;

  /// Zeros out the encryption key in memory.
  void dispose() {
    CryptoEngine.zeroMemory(encryptionKey);
  }
}
