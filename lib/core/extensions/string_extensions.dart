/// Useful String extensions used throughout Safira.
extension SafiraStringX on String {
  /// Returns true if the string is null, empty, or whitespace-only.
  bool get isBlank => trim().isEmpty;

  /// Returns true if the string has meaningful content.
  bool get isNotBlank => !isBlank;

  /// Truncates the string to [maxLength] chars, appending [ellipsis] if needed.
  String truncate(int maxLength, {String ellipsis = '…'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Masks the string, showing only the last [visibleChars] characters.
  /// Example: 'mypassword' → '•••••••ord'
  String mask({int visibleChars = 3, String maskChar = '•'}) {
    if (length <= visibleChars) return this;
    final visible = substring(length - visibleChars);
    final masked = maskChar * (length - visibleChars);
    return '$masked$visible';
  }

  /// Converts a string to title case.
  String toTitleCase() => split(' ')
      .map((word) => word.isEmpty ? word : '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .join(' ');

  /// Returns password strength score (0-4) based on entropy.
  int get passwordStrengthScore {
    if (length < 8) return 0;

    var score = 0;
    if (length >= 12) score++;
    if (length >= 16) score++;
    if (contains(RegExp(r'[A-Z]')) && contains(RegExp(r'[a-z]'))) score++;
    if (contains(RegExp(r'[0-9]'))) score++;
    if (contains(RegExp(r'[!@#\$%^&*()_+\-=\[\]{}|;:,.<>?]'))) score++;

    return score.clamp(0, 4);
  }

  /// Returns a human-readable strength label.
  String get passwordStrengthLabel => switch (passwordStrengthScore) {
        0 => 'Very Weak',
        1 => 'Weak',
        2 => 'Fair',
        3 => 'Strong',
        _ => 'Very Strong',
      };

  /// Calculates Shannon entropy of the string in bits.
  double get shannonEntropy {
    if (isEmpty) return 0;
    final freq = <String, int>{};
    for (final char in split('')) {
      freq[char] = (freq[char] ?? 0) + 1;
    }
    return freq.values.fold(0.0, (entropy, count) {
      final p = count / length;
      return entropy - p * (p > 0 ? (p * 3.321928).floorToDouble() : 0);
    });
  }

  /// Converts a hex string to a Uint8List.
  List<int> get hexToBytes {
    final result = <int>[];
    for (var i = 0; i < length; i += 2) {
      result.add(int.parse(substring(i, i + 2), radix: 16));
    }
    return result;
  }

  /// Returns the domain from a URL string.
  String get domain {
    try {
      final uri = Uri.parse(this);
      return uri.host.replaceFirst('www.', '');
    } catch (_) {
      return this;
    }
  }

  /// Returns true if the string looks like a valid URL.
  bool get isValidUrl {
    try {
      final uri = Uri.parse(this);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the string looks like a valid email address.
  bool get isValidEmail => RegExp(
        r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(this);
}

/// Extensions on nullable strings.
extension SafiraNullableStringX on String? {
  /// Returns true if null or blank.
  bool get isNullOrBlank => this == null || this!.isBlank;

  /// Returns the string or an empty string if null.
  String get orEmpty => this ?? '';
}
