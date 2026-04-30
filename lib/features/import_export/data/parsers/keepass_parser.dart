/// Parses a KeePass CSV export into a list of vault entry maps.
///
/// KeePass CSV columns (default export):
///   Account, Login Name, Password, Web Site, Comments
///
/// KeePass XML (KDBX) parsing is a future enhancement — the XML
/// structure requires a proper parser (or the kdbx package).
class KeePassParser {
  /// Parses [csvString] and returns a list of normalized entry maps.
  ///
  /// Throws [KeePassParseException] on invalid input.
  List<Map<String, dynamic>> parseCsv(String csvString) {
    final lines = _splitLines(csvString);
    if (lines.isEmpty) {
      throw const KeePassParseException('Empty CSV file');
    }

    // Detect header
    final header = _parseLine(lines.first);
    if (header.isEmpty) {
      throw const KeePassParseException('Could not parse CSV header');
    }

    final nameIdx = _findColumn(header, ['Account', 'Name', 'Title']);
    final userIdx =
        _findColumn(header, ['Login Name', 'Username', 'User Name']);
    final passIdx = _findColumn(header, ['Password']);
    final urlIdx = _findColumn(header, ['Web Site', 'URL', 'Url']);
    final notesIdx = _findColumn(header, ['Comments', 'Notes']);

    final results = <Map<String, dynamic>>[];

    for (int i = 1; i < lines.length; i++) {
      final cols = _parseLine(lines[i]);
      if (cols.isEmpty || cols.every((c) => c.trim().isEmpty)) continue;

      results.add({
        'type': 'login',
        'name': _safeGet(cols, nameIdx),
        'username': _safeGet(cols, userIdx),
        'password': _safeGet(cols, passIdx),
        'url': _safeGet(cols, urlIdx),
        'notes': notesIdx >= 0 ? _safeGet(cols, notesIdx) : null,
        'totp': null,
        'favorite': false,
      });
    }

    if (results.isEmpty) {
      throw const KeePassParseException(
          'No entries found in CSV file');
    }

    return results;
  }

  // ── Internal helpers ────────────────────────────────────────────────────

  List<String> _splitLines(String csv) {
    return csv
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
  }

  /// RFC 4180 compliant CSV line splitter.
  List<String> _parseLine(String line) {
    final result = <String>[];
    final buf = StringBuffer();
    bool inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buf.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(buf.toString());
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    result.add(buf.toString());
    return result;
  }

  int _findColumn(List<String> header, List<String> candidates) {
    for (final candidate in candidates) {
      final idx = header.indexWhere(
          (h) => h.trim().toLowerCase() == candidate.toLowerCase());
      if (idx >= 0) return idx;
    }
    return -1;
  }

  String _safeGet(List<String> cols, int idx) {
    if (idx < 0 || idx >= cols.length) return '';
    return cols[idx].trim();
  }
}

class KeePassParseException implements Exception {
  const KeePassParseException(this.message);
  final String message;

  @override
  String toString() => 'KeePassParseException: $message';
}
