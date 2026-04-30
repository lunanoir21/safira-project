import 'package:flutter_test/flutter_test.dart';
import 'package:safira/core/security/totp_engine.dart';

void main() {
  late TotpEngine engine;

  setUp(() => engine = TotpEngine());

  group('TotpEngine.generate', () {
    // RFC 6238 test vector: secret = '12345678901234567890' (ASCII)
    // At T=0 (unix epoch) with 30s period, the TOTP should be deterministic.
    const rfcSecret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ'; // base32 of above

    test('returns 6-digit string', () {
      final code = engine.generate(rfcSecret);
      expect(code.length, 6);
      expect(int.tryParse(code), isNotNull);
    });

    test('same secret produces same code within the same window', () {
      final c1 = engine.generate(rfcSecret);
      final c2 = engine.generate(rfcSecret);
      expect(c1, c2);
    });

    test('supports 8-digit codes', () {
      final code = engine.generate(rfcSecret, digits: 8);
      expect(code.length, 8);
    });
  });

  group('TotpEngine.parseOtpAuthUri', () {
    test('parses valid otpauth URI', () {
      const uri =
          'otpauth://totp/Example%3Aalice%40example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example&algorithm=SHA1&digits=6&period=30';
      final parsed = engine.parseOtpAuthUri(uri);
      expect(parsed.secret, 'JBSWY3DPEHPK3PXP');
      expect(parsed.issuer, 'Example');
      expect(parsed.digits, 6);
      expect(parsed.period, 30);
    });

    test('throws on invalid URI scheme', () {
      expect(
        () => engine.parseOtpAuthUri('https://example.com'),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on missing secret', () {
      expect(
        () => engine.parseOtpAuthUri(
            'otpauth://totp/Issuer:user?issuer=Issuer'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('TotpEngine.remainingSeconds', () {
    test('returns value between 1 and 30', () {
      final secs = engine.remainingSeconds();
      expect(secs, greaterThanOrEqualTo(1));
      expect(secs, lessThanOrEqualTo(30));
    });
  });
}
