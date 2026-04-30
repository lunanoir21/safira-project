// lib/core/security/crypto_engine.dart
// PRODUCTION — AES-256-GCM with static API + storage serialisation helpers.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../constants/app_constants.dart';
import '../errors/exceptions.dart';

// ─── EncryptedPayload ────────────────────────────────────────────────────────

/// Immutable container for AES-GCM encrypted output.
///
/// Binary layout (toBytes / fromBytes):
///   [nonce 12 B] [tag 16 B] [ciphertext N B]
///
/// String layout (toStorageString / fromStorageString):
///   "&lt;nonce_b64&gt;:&lt;tag_b64&gt;:&lt;ciphertext_b64&gt;"
///   Used for plain-text Isar fields such as encryptedSentinel.
final class EncryptedPayload {
  final Uint8List nonce;
  final Uint8List tag;
  final Uint8List ciphertext;

  const EncryptedPayload({
    required this.nonce,
    required this.tag,
    required this.ciphertext,
  });

  // Alias: `mac` == `tag` for backward compatibility with existing code.
  Uint8List get mac => tag;

  // ── Binary serialisation ─────────────────────────────────────────────

  factory EncryptedPayload.fromBytes(Uint8List bytes) {
    const nl = CryptoConstants.aesNonceLength;
    const tl = CryptoConstants.aesTagLength;
    if (bytes.length < nl + tl) {
      throw const CryptoException(message: 'Payload too short');
    }
    return EncryptedPayload(
      nonce: bytes.sublist(0, nl),
      tag: bytes.sublist(nl, nl + tl),
      ciphertext: bytes.sublist(nl + tl),
    );
  }

  Uint8List toBytes() {
    final out = Uint8List(nonce.length + tag.length + ciphertext.length);
    var o = 0;
    out.setRange(o, o + nonce.length, nonce);
    o += nonce.length;
    out.setRange(o, o + tag.length, tag);
    o += tag.length;
    out.setRange(o, o + ciphertext.length, ciphertext);
    return out;
  }

  // ── String serialisation (for Isar text fields) ──────────────────────

  /// Encodes as "&lt;nonce_b64&gt;:&lt;tag_b64&gt;:&lt;ciphertext_b64&gt;".
  String toStorageString() =>
      '${base64.encode(nonce)}:${base64.encode(tag)}:${base64.encode(ciphertext)}';

  factory EncryptedPayload.fromStorageString(String s) {
    final parts = s.split(':');
    if (parts.length != 3) {
      throw const CryptoException(message: 'Invalid storage string format');
    }
    return EncryptedPayload(
      nonce: base64.decode(parts[0]),
      tag: base64.decode(parts[1]),
      ciphertext: base64.decode(parts[2]),
    );
  }
}

// ─── CryptoEngine ────────────────────────────────────────────────────────────

/// Stateless AES-256-GCM encryption/decryption engine.
///
/// Security properties:
/// - Unique random nonce (12 B) per encryption — nonce reuse is catastrophic.
/// - 128-bit authentication tag — any tampering causes MAC failure.
/// - Keys never persisted — only live in SessionManager's locked memory.
///
/// All methods are available as **static calls**.
/// The [instance] singleton is kept for backward compatibility.
final class CryptoEngine {
  CryptoEngine._();

  static final CryptoEngine instance = CryptoEngine._();

  static final _algorithm = AesGcm.with256bits(
    nonceLength: CryptoConstants.aesNonceLength,
  );
  static final _rng = Random.secure();

  // ── Encrypt ───────────────────────────────────────────────────────────

  /// Encrypts [plaintext] with AES-256-GCM using [key].
  /// A fresh random nonce is generated for every call.
  static Future<EncryptedPayload> encrypt({
    required Uint8List plaintext,
    required Uint8List key,
    Uint8List? associatedData,
  }) async {
    try {
      final nonce = generateRandomBytes(CryptoConstants.aesNonceLength);
      final box = await _algorithm.encrypt(
        plaintext,
        secretKey: SecretKey(key),
        nonce: nonce,
        aad: associatedData ?? Uint8List(0),
      );
      return EncryptedPayload(
        nonce: Uint8List.fromList(nonce),
        tag: Uint8List.fromList(box.mac.bytes),
        ciphertext: Uint8List.fromList(box.cipherText),
      );
    } on Object catch (e) {
      throw CryptoException(message: 'Encryption failed: $e', cause: e);
    }
  }

  // ── Decrypt ───────────────────────────────────────────────────────────

  /// Decrypts [payload] with AES-256-GCM using [key].
  /// Throws [CryptoException] if MAC verification fails.
  static Future<Uint8List> decrypt({
    required EncryptedPayload payload,
    required Uint8List key,
    Uint8List? associatedData,
  }) async {
    try {
      final box = SecretBox(
        payload.ciphertext,
        nonce: payload.nonce,
        mac: Mac(payload.tag),
      );
      final plain = await _algorithm.decrypt(
        box,
        secretKey: SecretKey(key),
        aad: associatedData ?? Uint8List(0),
      );
      return Uint8List.fromList(plain);
    } on SecretBoxAuthenticationError {
      throw const CryptoException(
        message: 'MAC verification failed — wrong key or tampered data.',
      );
    } on Object catch (e) {
      throw CryptoException(message: 'Decryption failed: $e', cause: e);
    }
  }

  // ── Utilities ─────────────────────────────────────────────────────────

  static Uint8List generateRandomBytes(int length) {
    final b = Uint8List(length);
    for (var i = 0; i < length; i++) b[i] = _rng.nextInt(256);
    return b;
  }

  /// Constant-time comparison — prevents timing side-channels.
  static bool constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) diff |= a[i] ^ b[i];
    return diff == 0;
  }

  /// Overwrites [bytes] with zeros (best-effort memory zeroing).
  static void zeroMemory(Uint8List bytes) {
    for (var i = 0; i < bytes.length; i++) bytes[i] = 0;
  }
}
