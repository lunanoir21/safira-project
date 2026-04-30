import 'dart:math';

import 'package:equatable/equatable.dart';

/// Advanced password generator using cryptographically secure randomness.
///
/// Uses [Random.secure] which is backed by the OS CSPRNG (urandom/CryptGenRandom).
/// Never use [Random] (mersenne twister) for security-sensitive operations.
final class PasswordGenerator {
  PasswordGenerator._();

  static final PasswordGenerator instance = PasswordGenerator._();

  static const _lowercase = 'abcdefghijklmnopqrstuvwxyz';
  static const _uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  static const _digits = '0123456789';
  static const _symbols = '!@#\$%^&*()_+-=[]{}|;:,.<>?';
  static const _ambiguous = 'Il1O0o';
  static const _pronounceableVowels = 'aeiou';
  static const _pronounceableConsonants = 'bcdfghjklmnpqrstvwxyz';

  final _random = Random.secure();

  /// Generates a password according to [options].
  String generate(PasswordOptions options) {
    assert(options.length >= 4, 'Password length must be at least 4');

    if (options.pronounceable) {
      return _generatePronounceable(options);
    }

    return _generateRandom(options);
  }

  /// Generates a passphrase from random words separated by [separator].
  String generatePassphrase({
    int wordCount = 4,
    String separator = '-',
    bool capitalize = true,
    bool includeNumber = true,
  }) {
    final words = List.generate(wordCount, (_) => _randomWord());
    final phrase = words
        .map((w) => capitalize ? '${w[0].toUpperCase()}${w.substring(1)}' : w)
        .join(separator);

    if (includeNumber) {
      return '$phrase$separator${_random.nextInt(9999).toString().padLeft(4, '0')}';
    }

    return phrase;
  }

  /// Calculates the entropy of a password in bits.
  static double calculateEntropy({
    required int length,
    required int charsetSize,
  }) {
    if (charsetSize <= 0 || length <= 0) return 0;
    return length * (charsetSize.toDouble().logBase2());
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  String _generateRandom(PasswordOptions options) {
    final charset = _buildCharset(options);
    if (charset.isEmpty) return '';

    String password;
    var attempts = 0;

    do {
      password = List.generate(
        options.length,
        (_) => charset[_random.nextInt(charset.length)],
      ).join();
      attempts++;

      // Safety valve — should never need more than a few attempts
      if (attempts > 100) break;
    } while (!_meetsRequirements(password, options));

    return password;
  }

  String _generatePronounceable(PasswordOptions options) {
    final buffer = StringBuffer();
    var useVowel = _random.nextBool();

    while (buffer.length < options.length) {
      if (useVowel) {
        buffer.write(_pronounceableVowels[_random.nextInt(_pronounceableVowels.length)]);
      } else {
        buffer.write(_pronounceableConsonants[_random.nextInt(_pronounceableConsonants.length)]);
      }
      useVowel = !useVowel;
    }

    var result = buffer.toString().substring(0, options.length);

    if (options.includeUppercase) {
      final idx = _random.nextInt(result.length);
      result = result.substring(0, idx) +
          result[idx].toUpperCase() +
          result.substring(idx + 1);
    }

    if (options.includeDigits) {
      final idx = _random.nextInt(result.length);
      result = result.substring(0, idx) +
          _digits[_random.nextInt(_digits.length)] +
          result.substring(idx + 1);
    }

    return result;
  }

  String _buildCharset(PasswordOptions options) {
    final buffer = StringBuffer();

    if (options.includeLowercase) buffer.write(_lowercase);
    if (options.includeUppercase) buffer.write(_uppercase);
    if (options.includeDigits) buffer.write(_digits);
    if (options.includeSymbols) buffer.write(_symbols);

    var charset = buffer.toString();

    if (options.excludeAmbiguous) {
      charset = charset.split('').where((c) => !_ambiguous.contains(c)).join();
    }

    if (options.customExclude.isNotEmpty) {
      charset = charset.split('').where((c) => !options.customExclude.contains(c)).join();
    }

    return charset;
  }

  bool _meetsRequirements(String password, PasswordOptions options) {
    if (options.includeLowercase && !password.contains(RegExp(r'[a-z]'))) return false;
    if (options.includeUppercase && !password.contains(RegExp(r'[A-Z]'))) return false;
    if (options.includeDigits && !password.contains(RegExp(r'[0-9]'))) return false;
    if (options.includeSymbols &&
        !password.contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) return false;
    return true;
  }

  String _randomWord() {
    // Simple pronounceable word generator (syllable-based)
    final syllableCount = 2 + _random.nextInt(2);
    final buffer = StringBuffer();

    for (var i = 0; i < syllableCount; i++) {
      buffer.write(_pronounceableConsonants[_random.nextInt(_pronounceableConsonants.length)]);
      buffer.write(_pronounceableVowels[_random.nextInt(_pronounceableVowels.length)]);
    }

    return buffer.toString();
  }
}

/// Configuration options for password generation.
final class PasswordOptions extends Equatable {
  const PasswordOptions({
    this.length = 16,
    this.includeLowercase = true,
    this.includeUppercase = true,
    this.includeDigits = true,
    this.includeSymbols = true,
    this.excludeAmbiguous = false,
    this.pronounceable = false,
    this.customExclude = '',
  });

  final int length;
  final bool includeLowercase;
  final bool includeUppercase;
  final bool includeDigits;
  final bool includeSymbols;
  final bool excludeAmbiguous;
  final bool pronounceable;
  final String customExclude;

  PasswordOptions copyWith({
    int? length,
    bool? includeLowercase,
    bool? includeUppercase,
    bool? includeDigits,
    bool? includeSymbols,
    bool? excludeAmbiguous,
    bool? pronounceable,
    String? customExclude,
  }) =>
      PasswordOptions(
        length: length ?? this.length,
        includeLowercase: includeLowercase ?? this.includeLowercase,
        includeUppercase: includeUppercase ?? this.includeUppercase,
        includeDigits: includeDigits ?? this.includeDigits,
        includeSymbols: includeSymbols ?? this.includeSymbols,
        excludeAmbiguous: excludeAmbiguous ?? this.excludeAmbiguous,
        pronounceable: pronounceable ?? this.pronounceable,
        customExclude: customExclude ?? this.customExclude,
      );

  @override
  List<Object?> get props => [
        length,
        includeLowercase,
        includeUppercase,
        includeDigits,
        includeSymbols,
        excludeAmbiguous,
        pronounceable,
        customExclude,
      ];
}

extension on double {
  double logBase2() => this <= 0 ? 0 : (log(this) / log(2));
}
