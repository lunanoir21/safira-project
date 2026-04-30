import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/errors/exceptions.dart';

/// Core cryptographic engine for Safira.
///
/// Provides AES-256-GCM authenticated encryption and decryption.
/// All methods are stateless and pure — no side effects.
///
/// Security properties:
/// - AES-256-GCM provides both confidentiality and authenticity
/// - Unique random nonce per encryption operation (prevents nonce reuse)
/// - Authentication tag (128-bit) detects any tampering
/// - No key material is ever stored — keys live only in memory
final class CryptoEngine {
  CryptoEngine._();

  static final CryptoEngine instance = CryptoEngine._();

  static final _algorithm = AesGcm.with256bits(
    nonceLength: CryptoConstants.aesNonceLength,
  );

  static final _secureRandom = Random.secure();

  /// Encrypts [plaintext] bytes using [key] with AES-256-GCM.
  ///
  /// Returns a [EncryptedPayload] containing the ciphertext, nonce, and MAC.
  /// Each call generates a new random nonce — NEVER reuse nonces.
  ///
  /// Throws [CryptoException] on failure.
  Future<EncryptedPayload> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    Uint8List? associatedData,
  }) async {
    try {
      final secretKey = SecretKey(key);
      final nonce = _generateNonce();

      final secretBox = await _algorithm.encrypt(
        plaintext,
        secretKey: secretKey,
        nonce: nonce,
        aad: associatedData ?? Uint8List(0),
      );

      return EncryptedPayload(
        ciphertext: Uint8List.fromList(secretBox.cipherText),
        nonce: Uint8List.fromList(nonce),
        mac: Uint8List.fromList(secretBox.mac.bytes),
      );
    } on Object catch (e, st) {
      throw CryptoException(
        message: 'AES-256-GCM encryption failed',
        cause: e,
      );
    }
  }

  /// Decrypts [payload] using [key] with AES-256-GCM.
  ///
  /// Verifies the authentication tag before returning plaintext.
  /// Returns null if authentication fails (wrong key or tampered data).
  ///
  /// Throws [CryptoException] on failure.
  Future<Uint8List?> decrypt({
    required EncryptedPayload payload,
    required Uint8List key,
    Uint8List? associatedData,
  }) async {
    try {
      final secretKey = SecretKey(key);
      final secretBox = SecretBox(
        payload.ciphertext,
        nonce: payload.nonce,
        mac: Mac(payload.mac),
      );

      final plaintext = await _algorithm.decrypt(
        secretBox,
        secretKey: secretKey,
        aad: associatedData ?? Uint8List(0),
      );

      return Uint8List.fromList(plaintext);
    } on SecretBoxAuthenticationError {
      // Authentication failed — wrong key or tampered data
      return null;
    } on Object catch (e, st) {
      throw CryptoException(
        message: 'AES-256-GCM decryption failed',
        cause: e,
      );
    }
  }

  /// Generates a cryptographically secure random nonce.
  List<int> _generateNonce() {
    final nonce = Uint8List(CryptoConstants.aesNonceLength);
    for (var i = 0; i < nonce.length; i++) {
      nonce[i] = _secureRandom.nextInt(256);
    }
    return nonce;
  }

  /// Generates [length] cryptographically secure random bytes.
  static Uint8List generateRandomBytes(int length) {
    final bytes = Uint8List(length);
    for (var i = 0; i < length; i++) {
      bytes[i] = _secureRandom.nextInt(256);
    }
    return bytes;
  }

  /// Constant-time comparison to prevent timing attacks.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Zeroes out a byte array to remove sensitive data from memory.
  static void zeroMemory(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = 0;
    }
  }
}

/// Immutable container for AES-GCM encrypted output.
final class EncryptedPayload {
  const EncryptedPayload({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });

  /// Factory to deserialize from a combined byte array.
  /// Format: [nonce (12 bytes)] [mac (16 bytes)] [ciphertext (variable)]
  factory EncryptedPayload.fromBytes(Uint8List bytes) {
    if (bytes.length < CryptoConstants.aesNonceLength + CryptoConstants.aesTagLength) {
      throw const CryptoException(message: 'Invalid encrypted payload length');
    }

    var offset = 0;
    final nonce = bytes.sublist(offset, offset + CryptoConstants.aesNonceLength);
    offset += CryptoConstants.aesNonceLength;

    final mac = bytes.sublist(offset, offset + CryptoConstants.aesTagLength);
    offset += CryptoConstants.aesTagLength;

    final ciphertext = bytes.sublist(offset);

    return EncryptedPayload(
      ciphertext: ciphertext,
      nonce: nonce,
      mac: mac,
    );
  }

  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  /// Serializes to combined byte array.
  /// Format: [nonce (12 bytes)] [mac (16 bytes)] [ciphertext (variable)]
  Uint8List toBytes() {
    final result = Uint8List(
      CryptoConstants.aesNonceLength + CryptoConstants.aesTagLength + ciphertext.length,
    );
    var offset = 0;

    result.setRange(offset, offset + nonce.length, nonce);
    offset += nonce.length;

    result.setRange(offset, offset + mac.length, mac);
    offset += mac.length;

    result.setRange(offset, offset + ciphertext.length, ciphertext);

    return result;
  }
}
