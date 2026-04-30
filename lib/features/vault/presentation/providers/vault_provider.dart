// lib/features/vault/presentation/providers/vault_provider.dart
// PRODUCTION — real Isar queries, AES-256-GCM encrypt/decrypt, full CRUD.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/security/crypto_engine.dart';
import '../../../../shared/models/vault_entry_model.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../shared/providers/database_provider.dart';
import '../../../../shared/providers/session_provider.dart';

part 'vault_provider.g.dart';

// ─── DTO ─────────────────────────────────────────────────────────────────────

/// Decrypted vault entry exposed to the UI.
class VaultEntry {
  final Id id;
  final String title;
  final String category;
  final String? username;
  final String? url;
  final String? notes;
  final List<String> tags;
  final bool isFavorite;
  final bool isDeleted;
  final bool hasTOTP;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Sensitive data — only populated after explicit [VaultNotifier.decryptEntry].
  final String? password;
  final String? totpSecret;
  final Map<String, String> customFields;

  const VaultEntry({
    required this.id,
    required this.title,
    required this.category,
    this.username,
    this.url,
    this.notes,
    this.tags = const [],
    this.isFavorite = false,
    this.isDeleted = false,
    this.hasTOTP = false,
    required this.createdAt,
    required this.updatedAt,
    this.password,
    this.totpSecret,
    this.customFields = const {},
  });

  VaultEntry copyWith({
    String? title,
    String? category,
    String? username,
    String? url,
    String? notes,
    List<String>? tags,
    bool? isFavorite,
    bool? isDeleted,
    bool? hasTOTP,
    DateTime? updatedAt,
    String? password,
    String? totpSecret,
    Map<String, String>? customFields,
  }) =>
      VaultEntry(
        id: id,
        title: title ?? this.title,
        category: category ?? this.category,
        username: username ?? this.username,
        url: url ?? this.url,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        isFavorite: isFavorite ?? this.isFavorite,
        isDeleted: isDeleted ?? this.isDeleted,
        hasTOTP: hasTOTP ?? this.hasTOTP,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        password: password ?? this.password,
        totpSecret: totpSecret ?? this.totpSecret,
        customFields: customFields ?? this.customFields,
      );
}

// ─── State ────────────────────────────────────────────────────────────────────

sealed class VaultState {
  const VaultState();
}

final class VaultLoading extends VaultState {
  const VaultLoading();
}

final class VaultLoaded extends VaultState {
  const VaultLoaded({
    required this.entries,
    this.filteredEntries,
    this.searchQuery = '',
    this.activeCategory,
  });

  final List<VaultEntry> entries;

  /// Non-null when a search/filter is active.
  final List<VaultEntry>? filteredEntries;
  final String searchQuery;
  final String? activeCategory;

  List<VaultEntry> get displayedEntries => filteredEntries ?? entries;

  VaultLoaded copyWith({
    List<VaultEntry>? entries,
    List<VaultEntry>? filteredEntries,
    String? searchQuery,
    String? activeCategory,
    bool clearFilter = false,
  }) =>
      VaultLoaded(
        entries: entries ?? this.entries,
        filteredEntries: clearFilter ? null : (filteredEntries ?? this.filteredEntries),
        searchQuery: searchQuery ?? this.searchQuery,
        activeCategory: clearFilter ? null : (activeCategory ?? this.activeCategory),
      );
}

final class VaultError extends VaultState {
  const VaultError({required this.message});
  final String message;
}

// ─── Notifier ────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class VaultNotifier extends _$VaultNotifier {
  @override
  VaultState build() {
    // Re-load whenever the app transitions to unlocked.
    ref.listen(appStateNotifierProvider, (prev, next) {
      if (!prev!.isUnlocked && next.isUnlocked) {
        _loadEntries();
      }
      if (prev.isUnlocked && !next.isUnlocked) {
        // Clear entries from memory on lock.
        state = const VaultLoaded(entries: []);
      }
    });

    // If already unlocked at build time, load immediately.
    if (ref.read(appStateNotifierProvider).isUnlocked) {
      _loadEntries();
    }

    return const VaultLoading();
  }

  // ── Internal helpers ──────────────────────────────────────────────────

  Uint8List? _getKey() =>
      ref.read(sessionManagerProvider).encryptionKey;

  Future<void> _loadEntries() async {
    state = const VaultLoading();
    try {
      final key = _getKey();
      if (key == null) {
        state = const VaultLoaded(entries: []);
        return;
      }

      final isar = await ref.read(databaseProvider.future);
      final models = await isar.vaultEntryModels
          .where()
          .filter()
          .isDeletedEqualTo(false)
          .findAll();

      // Decrypt metadata-only fields (sensitive fields stay encrypted).
      final entries = models.map((m) => _modelToEntry(m)).toList();

      // Sort: favourites first, then by updatedAt desc.
      entries.sort((a, b) {
        if (a.isFavorite != b.isFavorite) {
          return a.isFavorite ? -1 : 1;
        }
        return b.updatedAt.compareTo(a.updatedAt);
      });

      state = VaultLoaded(entries: entries);
    } catch (e) {
      state = VaultError(message: e.toString());
    }
  }

  /// Maps Isar model → VaultEntry (metadata only, no decryption).
  VaultEntry _modelToEntry(VaultEntryModel m) => VaultEntry(
        id: m.id,
        title: m.title,
        category: m.category,
        username: m.username,
        url: m.url,
        notes: m.notes,
        tags: List<String>.from(m.tags),
        isFavorite: m.isFavorite,
        isDeleted: m.isDeleted,
        hasTOTP: m.hasTOTP,
        createdAt: m.createdAt,
        updatedAt: m.updatedAt,
      );

  // ── CRUD ─────────────────────────────────────────────────────────────

  /// Creates a new encrypted vault entry.
  Future<void> createEntry({
    required String title,
    required String category,
    String? username,
    String? url,
    String? password,
    String? notes,
    String? totpSecret,
    List<String> tags = const [],
    Map<String, String> customFields = const {},
  }) async {
    final key = _getKey();
    if (key == null) throw StateError('Vault is locked');

    // Build sensitive data payload.
    final sensitive = VaultSensitiveData(
      password: password ?? '',
      totpSecret: totpSecret,
      customFields: customFields,
    );
    final sensitiveJson = jsonEncode(sensitive.toJson());
    final payload = await CryptoEngine.encrypt(
      plaintext: Uint8List.fromList(sensitiveJson.codeUnits),
      key: key,
    );

    final now = DateTime.now().toUtc();
    final model = VaultEntryModel(
      title: title,
      category: category,
      username: username,
      url: url,
      notes: notes,
      tags: tags,
      hasTOTP: totpSecret != null && totpSecret.isNotEmpty,
      encryptedData: payload.toStorageString(),
      createdAt: now,
      updatedAt: now,
    );

    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.vaultEntryModels.put(model);
    });

    await _loadEntries();
  }

  /// Updates an existing vault entry; re-encrypts sensitive data.
  Future<void> updateEntry({
    required Id entryId,
    String? title,
    String? category,
    String? username,
    String? url,
    String? password,
    String? notes,
    String? totpSecret,
    List<String>? tags,
    Map<String, String>? customFields,
  }) async {
    final key = _getKey();
    if (key == null) throw StateError('Vault is locked');

    final isar = await ref.read(databaseProvider.future);
    final model = await isar.vaultEntryModels.get(entryId);
    if (model == null) throw StateError('Entry not found: $entryId');

    // Decrypt existing sensitive data to merge with updates.
    final existingPayload =
        EncryptedPayload.fromStorageString(model.encryptedData);
    final existingPlaintext = await CryptoEngine.decrypt(
      payload: existingPayload,
      key: key,
    );
    final existingJson = jsonDecode(String.fromCharCodes(existingPlaintext))
        as Map<String, dynamic>;
    final existingSensitive = VaultSensitiveData.fromJson(existingJson);

    final merged = VaultSensitiveData(
      password: password ?? existingSensitive.password,
      totpSecret: totpSecret ?? existingSensitive.totpSecret,
      customFields: customFields ?? existingSensitive.customFields,
    );

    final newPayload = await CryptoEngine.encrypt(
      plaintext:
          Uint8List.fromList(jsonEncode(merged.toJson()).codeUnits),
      key: key,
    );

    model
      ..title = title ?? model.title
      ..category = category ?? model.category
      ..username = username ?? model.username
      ..url = url ?? model.url
      ..notes = notes ?? model.notes
      ..tags = tags ?? model.tags
      ..hasTOTP = (merged.totpSecret?.isNotEmpty ?? false)
      ..encryptedData = newPayload.toStorageString()
      ..updatedAt = DateTime.now().toUtc();

    await isar.writeTxn(() async {
      await isar.vaultEntryModels.put(model);
    });

    await _loadEntries();
  }

  /// Toggles favourite flag for [entryId].
  Future<void> toggleFavorite(Id entryId) async {
    final isar = await ref.read(databaseProvider.future);
    final model = await isar.vaultEntryModels.get(entryId);
    if (model == null) return;

    model.isFavorite = !model.isFavorite;
    model.updatedAt = DateTime.now().toUtc();

    await isar.writeTxn(() async {
      await isar.vaultEntryModels.put(model);
    });

    await _loadEntries();
  }

  /// Soft-deletes an entry (moves to trash).
  Future<void> deleteEntry(Id entryId) async {
    final isar = await ref.read(databaseProvider.future);
    final model = await isar.vaultEntryModels.get(entryId);
    if (model == null) return;

    model.isDeleted = true;
    model.updatedAt = DateTime.now().toUtc();

    await isar.writeTxn(() async {
      await isar.vaultEntryModels.put(model);
    });

    await _loadEntries();
  }

  /// Permanently deletes an entry from Isar.
  Future<void> purgeEntry(Id entryId) async {
    final isar = await ref.read(databaseProvider.future);
    await isar.writeTxn(() async {
      await isar.vaultEntryModels.delete(entryId);
    });
    await _loadEntries();
  }

  // ── Decrypt on demand ─────────────────────────────────────────────────

  /// Returns a [VaultEntry] with sensitive fields populated.
  Future<VaultEntry?> decryptEntry(Id entryId) async {
    final key = _getKey();
    if (key == null) return null;

    final isar = await ref.read(databaseProvider.future);
    final model = await isar.vaultEntryModels.get(entryId);
    if (model == null) return null;

    final payload =
        EncryptedPayload.fromStorageString(model.encryptedData);
    final plaintext = await CryptoEngine.decrypt(
      payload: payload,
      key: key,
    );
    final json =
        jsonDecode(String.fromCharCodes(plaintext)) as Map<String, dynamic>;
    final sensitive = VaultSensitiveData.fromJson(json);

    return _modelToEntry(model).copyWith(
      password: sensitive.password,
      totpSecret: sensitive.totpSecret,
      customFields: sensitive.customFields,
    );
  }

  // ── Search & Filter ───────────────────────────────────────────────────

  void search(String query) {
    final current = state;
    if (current is! VaultLoaded) return;

    if (query.isEmpty) {
      state = current.copyWith(
        filteredEntries: null,
        searchQuery: '',
        clearFilter: true,
      );
      return;
    }

    final lower = query.toLowerCase();
    final filtered = current.entries.where((e) {
      return e.title.toLowerCase().contains(lower) ||
          (e.username?.toLowerCase().contains(lower) ?? false) ||
          (e.url?.toLowerCase().contains(lower) ?? false) ||
          e.tags.any((t) => t.toLowerCase().contains(lower));
    }).toList();

    state = current.copyWith(
      filteredEntries: filtered,
      searchQuery: query,
    );
  }

  void filterByCategory(String? category) {
    final current = state;
    if (current is! VaultLoaded) return;

    if (category == null) {
      state = current.copyWith(clearFilter: true);
      return;
    }

    final filtered = current.entries
        .where((e) => e.category == category)
        .toList();

    state = current.copyWith(
      filteredEntries: filtered,
      activeCategory: category,
    );
  }

  void clearSearch() {
    final current = state;
    if (current is! VaultLoaded) return;
    state = current.copyWith(clearFilter: true);
  }

  Future<void> refresh() => _loadEntries();
}
