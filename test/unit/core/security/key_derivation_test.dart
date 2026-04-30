import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:safira/core/security/key_derivation.dart';

void main() {
  late KeyDerivation kdf;

  setUp(() => kdf = KeyDerivation());

  group('KeyDerivation.derive', () {
    const password = 'correct-horse-battery-staple';

    test('derived key is 32 bytes (256-bit)', () async {
      final bundle = await kdf.derive(password: password);
      expect(bundle.key.length, 32);
    });

    test('salt is 16 bytes', () async {
      final bundle = await kdf.derive(password: password);
      expect(bundle.salt.length, 16);
    });

    test('generates unique salt on each call', () async {
      final b1 = await kdf.derive(password: password);
      final b2 = await kdf.derive(password: password);
      expect(b1.salt, isNot(equals(b2.salt)));
    });

    test('same password + salt = same key (deterministic)', () async {
      final b1 = await kdf.derive(password: password);
      final b2 = await kdf.deriveWithSalt(
        password: password,
        salt: b1.salt,
      );
      expect(b1.key, equals(b2.key));
    });

    test('different passwords produce different keys', () async {
      final b1 = await kdf.derive(password: 'password1');
      final b2 = await kdf.deriveWithSalt(
        password: 'password2',
        salt: b1.salt,
      );
      expect(b1.key, isNot(equals(b2.key)));
    });
  });

  group('KeyDerivation.verify', () {
    test('verify returns true for correct password', () async {
      const pw = 'my-master-password';
      final bundle = await kdf.derive(password: pw);
      final ok = await kdf.verify(
        password: pw,
        salt: bundle.salt,
        expectedKey: bundle.key,
      );
      expect(ok, isTrue);
    });

    test('verify returns false for wrong password', () async {
      const pw = 'my-master-password';
      const wrong = 'wrong-password';
      final bundle = await kdf.derive(password: pw);
      final ok = await kdf.verify(
        password: wrong,
        salt: bundle.salt,
        expectedKey: bundle.key,
      );
      expect(ok, isFalse);
    });
  });
}
