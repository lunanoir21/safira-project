// lib/features/auth/presentation/providers/auth_provider.dart
// PRODUCTION — real Argon2id verification, lockout, SessionManager wiring.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/security/crypto_engine.dart';
import '../../../../core/security/key_derivation.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../shared/models/vault_entry_model.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../shared/providers/database_provider.dart';
import '../../../../shared/providers/session_provider.dart';

part 'auth_provider.g.dart';

// ─── Constants ────────────────────────────────────────────────────────────────

const _kMaxAttempts = 5;
const _kLockoutDurationMinutes = 15;

// ─── State ────────────────────────────────────────────────────────────────────

enum AuthStatus {
  idle,
  verifying,
  success,
  failed,
  lockedOut,
}

class AuthState {
  final AuthStatus status;
  final int failedAttempts;
  final DateTime? lockoutUntil;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.idle,
    this.failedAttempts = 0,
    this.lockoutUntil,
    this.errorMessage,
  });

  bool get isLockedOut {
    if (lockoutUntil == null) return false;
    return DateTime.now().isBefore(lockoutUntil!);
  }

  Duration get remainingLockout {
    if (!isLockedOut) return Duration.zero;
    return lockoutUntil!.difference(DateTime.now());
  }

  AuthState copyWith({
    AuthStatus? status,
    int? failedAttempts,
    DateTime? lockoutUntil,
    String? errorMessage,
    bool clearError = false,
    bool clearLockout = false,
  }) =>
      AuthState(
        status: status ?? this.status,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockoutUntil: clearLockout ? null : (lockoutUntil ?? this.lockoutUntil),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  AuthState build() => const AuthState();

  // ── Unlock with password ──────────────────────────────────────────────

  /// Returns true if password is correct and vault is unlocked.
  Future<bool> unlockWithPassword(String password) async {
    // Guard: lockout check.
    if (state.isLockedOut) {
      state = state.copyWith(
        status: AuthStatus.lockedOut,
        errorMessage:
            'Too many failed attempts. Try again in ${state.remainingLockout.inMinutes + 1} min.',
      );
      return false;
    }

    if (password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.failed,
        errorMessage: 'Please enter your master password.',
      );
      return false;
    }

    state = state.copyWith(status: AuthStatus.verifying, clearError: true);

    try {
      // 1. Load vault metadata from Isar.
      final isar = await ref.read(databaseProvider.future);
      final metadata =
          await isar.vaultMetadataModels.where().findFirst();

      if (metadata == null) {
        // No vault exists — should not happen if onboarding was completed.
        state = state.copyWith(
          status: AuthStatus.failed,
          errorMessage: 'Vault not found. Please contact support.',
        );
        return false;
      }

      // 2. Re-derive the key using stored Argon2id params + salt.
      final keyBundle = await KeyDerivation.deriveKeyFromSalt(
        password: password,
        salt: metadata.argon2Salt,
        memoryKiB: metadata.argon2MemoryKiB,
        iterations: metadata.argon2Iterations,
        parallelism: metadata.argon2Parallelism,
      );

      // 3. Verify by decrypting the sentinel value.
      bool verified = false;
      try {
        final sentinelPayload =
            EncryptedPayload.fromStorageString(metadata.encryptedSentinel);
        final plaintext = await CryptoEngine.decrypt(
          payload: sentinelPayload,
          key: keyBundle.derivedKey,
        );
        verified =
            String.fromCharCodes(plaintext) == 'SAFIRA_VAULT_V1';
      } catch (_) {
        verified = false;
      }

      if (!verified) {
        keyBundle.zero();
        return _recordFailedAttempt();
      }

      // 4. Unlock session with derived key.
      final session = ref.read(sessionManagerProvider);
      session.unlock(keyBundle.derivedKey);
      keyBundle.zero();

      // 5. Update app state.
      ref.read(appStateNotifierProvider.notifier).setUnlocked(unlocked: true);

      state = state.copyWith(
        status: AuthStatus.success,
        failedAttempts: 0,
        clearLockout: true,
        clearError: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.failed,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  // ── Biometric unlock ──────────────────────────────────────────────────

  /// Placeholder for biometric unlock — real implementation requires local_auth
  /// and storing/retrieving the encrypted key from secure storage.
  Future<bool> unlockWithBiometric() async {
    state = state.copyWith(
      status: AuthStatus.failed,
      errorMessage: 'Biometric unlock not yet available on this platform.',
    );
    return false;
  }

  // ── Lock ─────────────────────────────────────────────────────────────

  void lock() {
    ref.read(sessionManagerProvider).lock();
    ref.read(appStateNotifierProvider.notifier).lock();
    state = const AuthState();
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  bool _recordFailedAttempt() {
    final attempts = state.failedAttempts + 1;
    if (attempts >= _kMaxAttempts) {
      final lockoutUntil = DateTime.now()
          .add(const Duration(minutes: _kLockoutDurationMinutes));
      state = state.copyWith(
        status: AuthStatus.lockedOut,
        failedAttempts: attempts,
        lockoutUntil: lockoutUntil,
        errorMessage:
            'Too many failed attempts. Locked for $_kLockoutDurationMinutes minutes.',
      );
    } else {
      final remaining = _kMaxAttempts - attempts;
      state = state.copyWith(
        status: AuthStatus.failed,
        failedAttempts: attempts,
        errorMessage:
            'Incorrect password. $remaining attempt${remaining == 1 ? "" : "s"} remaining.',
      );
    }
    return false;
  }
}
