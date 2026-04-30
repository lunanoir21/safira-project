import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:safira/core/security/crypto_engine.dart';

void main() {
  late CryptoEngine engine;
  late Uint8List key;

  setUp(() {
    engine = CryptoEngine();
    // 256-bit key (32 bytes)
    key = Uint8List.fromList(List.generate(32, (i) => i));
  });

  group('CryptoEngine.encrypt', () {
    test('returns non-empty ciphertext', () async {
      const plaintext = 'my secret password';
      final payload = await engine.encrypt(plaintext, key);
      expect(payload.ciphertext, isNotEmpty);
    });

    test('nonce is 12 bytes (AES-GCM)', () async {
      const plaintext = 'test';
      final payload = await engine.encrypt(plaintext, key);
      expect(payload.nonce.length, 12);
    });

    test('each encryption produces unique ciphertext (random nonce)', () async {
      const plaintext = 'hello';
      final p1 = await engine.encrypt(plaintext, key);
      final p2 = await engine.encrypt(plaintext, key);
      // Different nonces → different ciphertexts
      expect(p1.nonce, isNot(equals(p2.nonce)));
      expect(p1.ciphertext, isNot(equals(p2.ciphertext)));
    });
  });

  group('CryptoEngine.decrypt', () {
    test('round-trip: decrypt(encrypt(x)) == x', () async {
      const plaintext = 'round-trip secret!';
      final payload = await engine.encrypt(plaintext, key);
      final decrypted = await engine.decrypt(payload, key);
      expect(decrypted, plaintext);
    });

    test('throws on wrong key', () async {
      const plaintext = 'secure data';
      final payload = await engine.encrypt(plaintext, key);

      final wrongKey = Uint8List.fromList(List.generate(32, (i) => i + 1));
      expect(
        () => engine.decrypt(payload, wrongKey),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on tampered ciphertext', () async {
      const plaintext = 'tamper test';
      final payload = await engine.encrypt(plaintext, key);

      // Flip a byte in ciphertext
      final tampered = Uint8List.fromList(payload.ciphertext)
        ..[0] ^= 0xFF;
      final tamperedPayload = EncryptedPayload(
        ciphertext: tampered,
        nonce: payload.nonce,
        version: payload.version,
      );

      expect(
        () => engine.decrypt(tamperedPayload, key),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('CryptoEngine.constantTimeEquals', () {
    test('returns true for equal byte arrays', () {
      final a = Uint8List.fromList([1, 2, 3, 4]);
      final b = Uint8List.fromList([1, 2, 3, 4]);
      expect(CryptoEngine.constantTimeEquals(a, b), isTrue);
    });

    test('returns false for different byte arrays', () {
      final a = Uint8List.fromList([1, 2, 3, 4]);
      final b = Uint8List.fromList([1, 2, 3, 5]);
      expect(CryptoEngine.constantTimeEquals(a, b), isFalse);
    });

    test('returns false for different lengths', () {
      final a = Uint8List.fromList([1, 2, 3]);
      final b = Uint8List.fromList([1, 2, 3, 4]);
      expect(CryptoEngine.constantTimeEquals(a, b), isFalse);
    });
  });
}
