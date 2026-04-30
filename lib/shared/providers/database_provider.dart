import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safira/shared/models/vault_entry_model.dart';

part 'database_provider.g.dart';

/// Provides the singleton Isar database instance.
///
/// Opens the database lazily on first access.
/// The database is closed automatically when the provider is disposed.
@Riverpod(keepAlive: true)
Future<Isar> isarDatabase(IsarDatabaseRef ref) async {
  final dir = await getApplicationDocumentsDirectory();

  final isar = await Isar.open(
    [
      VaultEntryModelSchema,
      VaultMetadataModelSchema,
      AppSettingsModelSchema,
    ],
    directory: dir.path,
    name: 'safira_vault',
    inspector: false, // Disable inspector in production
  );

  ref.onDispose(isar.close);

  return isar;
}
