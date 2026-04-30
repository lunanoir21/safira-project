import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:safira/features/vault/presentation/providers/vault_provider.dart';

// ── Mocks ────────────────────────────────────────────────────────────────────

// Add mocks here once real Isar repository is injected via DI.
// For now we test the provider's initial state and state transitions.

void main() {
  group('VaultNotifier initial state', () {
    test('starts in VaultLoading state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(vaultProvider);
      expect(state, isA<VaultLoading>());
    });
  });

  group('VaultState sealed classes', () {
    test('VaultLoading is a VaultState', () {
      expect(const VaultLoading(), isA<VaultState>());
    });

    test('VaultLoaded holds entries', () {
      const loaded = VaultLoaded(entries: []);
      expect(loaded.entries, isEmpty);
    });

    test('VaultError holds message', () {
      const err = VaultError(message: 'something went wrong');
      expect(err.message, 'something went wrong');
    });
  });

  // TODO: Add integration-style tests once the Isar repository is wired:
  // - loadEntries() transitions to VaultLoaded
  // - loadEntries() transitions to VaultError on DB failure
  // - createEntry() appends to VaultLoaded.entries
  // - deleteEntry() removes from VaultLoaded.entries
  // - searchEntries() filters by query
}
