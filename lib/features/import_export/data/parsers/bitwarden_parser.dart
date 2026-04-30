import 'dart:convert';

/// Parses a Bitwarden JSON export into a list of vault entry maps.
///
/// Bitwarden exports look like:
/// ```json
/// {
///   "encrypted": false,
///   "items": [
///     {
///       "id": "...",
///       "name": "Example",
///       "type": 1,
///       "login": { "username": "user@example.com", "password": "hunter2",
///                  "uris": [{ "uri": "https://example.com" }],
///                  "totp": null },
///       "notes": null
///     }
///   ]
/// }
/// ```
class BitwardenParser {
  /// Parses [jsonString] and returns a list of normalized entry maps.
  ///
  /// Throws [BitwardenParseException] on invalid input.
  List<Map<String, dynamic>> parse(String jsonString) {
    late final Map<String, dynamic> root;
    try {
      root = json.decode(jsonString) as Map<String, dynamic>;
    } catch (_) {
      throw const BitwardenParseException('Invalid JSON format');
    }

    if (root['encrypted'] == true) {
      throw const BitwardenParseException(
          'Encrypted Bitwarden exports are not supported. '
          'Please export an unencrypted copy.');
    }

    final items = root['items'];
    if (items == null || items is! List) {
      throw const BitwardenParseException(
          'Missing "items" array in Bitwarden export');
    }

    final results = <Map<String, dynamic>>[];

    for (final rawItem in items) {
      if (rawItem is! Map<String, dynamic>) continue;

      final type = rawItem['type'] as int? ?? 0;

      // Type 1 = Login, Type 2 = Secure Note, Type 3 = Card, Type 4 = Identity
      if (type == 1) {
        results.add(_parseLogin(rawItem));
      } else if (type == 2) {
        results.add(_parseSecureNote(rawItem));
      }
      // Cards and identities are skipped for now
    }

    return results;
  }

  Map<String, dynamic> _parseLogin(Map<String, dynamic> item) {
    final login = item['login'] as Map<String, dynamic>? ?? {};
    final uris = login['uris'] as List<dynamic>? ?? [];
    final firstUri = uris.isNotEmpty
        ? (uris.first as Map<String, dynamic>)['uri'] as String? ?? ''
        : '';

    return {
      'type': 'login',
      'name': item['name'] as String? ?? 'Untitled',
      'username': login['username'] as String? ?? '',
      'password': login['password'] as String? ?? '',
      'url': firstUri,
      'totp': login['totp'] as String?,
      'notes': item['notes'] as String?,
      'favorite': item['favorite'] as bool? ?? false,
      'folderId': item['folderId'] as String?,
    };
  }

  Map<String, dynamic> _parseSecureNote(Map<String, dynamic> item) {
    return {
      'type': 'note',
      'name': item['name'] as String? ?? 'Untitled',
      'notes': item['notes'] as String?,
    };
  }
}

class BitwardenParseException implements Exception {
  const BitwardenParseException(this.message);
  final String message;

  @override
  String toString() => 'BitwardenParseException: $message';
}
