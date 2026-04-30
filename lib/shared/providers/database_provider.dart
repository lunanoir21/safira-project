// lib/shared/providers/database_provider.dart
// Production Isar singleton — opens once, kept alive, platform-aware path.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/vault_entry_model.dart';
import '../models/secure_note_model.dart';

part 'database_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Isar> database(DatabaseRef ref) async {
  final dir = await _resolveDbDirectory();

  // Return existing instance if already open (hot-restart safety).
  if (Isar.instanceNames.contains('safira')) {
    return Isar.getInstance('safira')!;
  }

  final isar = await Isar.open(
    [
      VaultEntryModelSchema,
      VaultMetadataModelSchema,
      AppSettingsModelSchema,
      SecureNoteModelSchema,
    ],
    directory: dir.path,
    name: 'safira',
    inspector: kDebugMode,
  );

  ref.onDispose(() {
    if (isar.isOpen) isar.close();
  });

  return isar;
}

Future<Directory> _resolveDbDirectory() async {
  if (Platform.isLinux || Platform.isMacOS || Platform.isWindows) {
    // Desktop: use app-support directory (hidden from user's home).
    return getApplicationSupportDirectory();
  }
  // Mobile: documents directory.
  return getApplicationDocumentsDirectory();
}
