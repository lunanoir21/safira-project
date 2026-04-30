import 'package:flutter_test/flutter_test.dart';
import 'package:safira/core/security/password_generator.dart';

void main() {
  late PasswordGenerator generator;

  setUp(() => generator = PasswordGenerator());

  group('PasswordGenerator.generate', () {
    test('returns password of requested length', () {
      for (final len in [8, 16, 24, 32, 64]) {
        final pw = generator.generate(
          const PasswordOptions(length: 0),
        );
        // Use explicit length in options
        final pw2 = generator.generate(
          PasswordOptions(length: len),
        );
        expect(pw2.length, len);
      }
    });

    test('includes uppercase when requested', () {
      final pw = generator.generate(
        const PasswordOptions(
          length: 50,
          includeUppercase: true,
          includeLowercase: false,
          includeNumbers: false,
          includeSymbols: false,
        ),
      );
      expect(pw.split('').every((c) => c == c.toUpperCase()), isTrue);
    });

    test('includes numbers when requested', () {
      final pw = generator.generate(
        const PasswordOptions(
          length: 50,
          includeUppercase: false,
          includeLowercase: false,
          includeNumbers: true,
          includeSymbols: false,
        ),
      );
      expect(pw.split('').every((c) => '0123456789'.contains(c)), isTrue);
    });

    test('generates unique passwords on consecutive calls', () {
      const opts = PasswordOptions(length: 16);
      final passwords = List.generate(10, (_) => generator.generate(opts));
      final unique = passwords.toSet();
      // Extremely unlikely to have duplicates with a CSPRNG
      expect(unique.length, greaterThan(1));
    });

    test('passphrase mode returns words separated by separator', () {
      final pw = generator.generatePassphrase(
        wordCount: 4,
        separator: '-',
      );
      expect(pw.split('-').length, 4);
    });
  });

  group('PasswordOptions validation', () {
    test('throws on zero-length password', () {
      expect(
        () => generator.generate(const PasswordOptions(length: 0)),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
