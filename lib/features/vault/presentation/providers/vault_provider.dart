import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safira/shared/models/vault_entry_model.dart';

part 'vault_provider.g.dart';

/// Vault provider — manages all vault entries.
@riverpod
class Vault extends _$Vault {
  @override
  VaultState build() {
    // Load entries on initialization
    _loadEntries();
    return const VaultLoading();
  }

  Future<void> _loadEntries() async {
    state = const VaultLoading();
    try {
      // TODO: Load from Isar + decrypt each entry
      await Future.delayed(const Duration(milliseconds: 300));
      state = const VaultLoaded(entries: []);
    } on Exception catch (e) {
      state = VaultError(message: e.toString());
    }
  }

  /// Creates a new vault entry.
  Future<void> createEntry(VaultEntryModel entry) async {
    // TODO: Encrypt entry data, save to Isar
    await _loadEntries();
  }

  /// Updates an existing entry.
  Future<void> updateEntry(VaultEntryModel entry) async {
    // TODO: Re-encrypt and update in Isar
    await _loadEntries();
  }

  /// Soft-deletes an entry (moves to trash).
  Future<void> deleteEntry(String id) async {
    // TODO: Mark as deleted in Isar
    await _loadEntries();
  }

  /// Toggles the favorite status of an entry.
  Future<void> toggleFavorite(String id) async {
    // TODO: Update in Isar
    await _loadEntries();
  }

  /// Searches entries by query.
  Future<void> search(String query) async {
    // TODO: Fuzzy search via Isar query
    await _loadEntries();
  }

  /// Filters entries by category.
  Future<void> filterByCategory(String category) async {
    // TODO: Filter via Isar query
    await _loadEntries();
  }

  /// Refreshes the vault (e.g., after import).
  Future<void> refresh() => _loadEntries();
}

// ─── State types ─────────────────────────────────────────────────────────────

sealed class VaultState {
  const VaultState();
}

final class VaultLoading extends VaultState {
  const VaultLoading();
}

final class VaultLoaded extends VaultState {
  const VaultLoaded({required this.entries});
  final List<VaultEntryModel> entries;
}

final class VaultError extends VaultState {
  const VaultError({required this.message});
  final String message;
}
