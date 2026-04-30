import 'package:flutter_test/flutter_test.dart';
import 'package:safira/core/extensions/string_extensions.dart';

void main() {
  group('String.isValidEmail', () {
    test('accepts valid emails', () {
      expect('user@example.com'.isValidEmail, isTrue);
      expect('alice+tag@mail.co.uk'.isValidEmail, isTrue);
      expect('test.name@domain.org'.isValidEmail, isTrue);
    });

    test('rejects invalid emails', () {
      expect('not-an-email'.isValidEmail, isFalse);
      expect('@nodomain.com'.isValidEmail, isFalse);
      expect('missing@'.isValidEmail, isFalse);
      expect(''.isValidEmail, isFalse);
    });
  });

  group('String.isValidUrl', () {
    test('accepts https URLs', () {
      expect('https://example.com'.isValidUrl, isTrue);
      expect('https://sub.domain.org/path?q=1'.isValidUrl, isTrue);
    });

    test('accepts http URLs', () {
      expect('http://localhost:8080'.isValidUrl, isTrue);
    });

    test('rejects invalid URLs', () {
      expect('not-a-url'.isValidUrl, isFalse);
      expect(''.isValidUrl, isFalse);
      expect('ftp://files.example.com'.isValidUrl, isFalse);
    });
  });

  group('String.passwordStrength', () {
    test('empty string has zero strength', () {
      expect(''.passwordStrength, 0.0);
    });

    test('short simple password has low strength', () {
      expect('abc'.passwordStrength, lessThan(0.3));
    });

    test('complex password has high strength', () {
      expect('C0rr3ct-H0rse-B4ttery!'.passwordStrength,
          greaterThan(0.7));
    });

    test('strength is between 0.0 and 1.0', () {
      for (final pw in ['', 'a', 'abcdef', 'Abc123!', 'V3ryS3cur3P@ss!']) {
        final s = pw.passwordStrength;
        expect(s, greaterThanOrEqualTo(0.0));
        expect(s, lessThanOrEqualTo(1.0));
      }
    });
  });

  group('String.toDisplayDomain', () {
    test('extracts domain from https URL', () {
      expect('https://github.com/login'.toDisplayDomain, 'github.com');
    });

    test('strips www prefix', () {
      expect('https://www.google.com'.toDisplayDomain, 'google.com');
    });

    test('returns original string if not a URL', () {
      expect('not-a-url'.toDisplayDomain, 'not-a-url');
    });

    test('returns empty for empty string', () {
      expect(''.toDisplayDomain, '');
    });
  });

  group('String.initials', () {
    test('returns two letters for two-word name', () {
      expect('John Doe'.initials, 'JD');
    });

    test('returns first letter for single word', () {
      expect('Alice'.initials, 'A');
    });

    test('returns empty for empty string', () {
      expect(''.initials, '');
    });
  });
}
