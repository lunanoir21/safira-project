// lib/features/onboarding/presentation/providers/onboarding_provider.dart
// PRODUCTION — derives Argon2id key, encrypts sentinel, persists to Isar.

import 'dart:typed_data';
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

part 'onboarding_provider.g.dart';

// ─── State ────────────────────────────────────────────────────────────────────

enum OnboardingStep {
  welcome,
  masterPassword,
  theme,
  biometric,
  done,
}

class OnboardingState {
  final OnboardingStep step;
  final bool isProcessing;
  final String? errorMessage;

  /// Argon2id parameters chosen during this session.
  final int memoryKiB;
  final int iterations;
  final int parallelism;

  const OnboardingState({
    this.step = OnboardingStep.welcome,
    this.isProcessing = false,
    this.errorMessage,
    this.memoryKiB = 65536, // 64 MiB — OWASP recommended minimum
    this.iterations = 3,
    this.parallelism = 4,
  });

  OnboardingState copyWith({
    OnboardingStep? step,
    bool? isProcessing,
    String? errorMessage,
    bool clearError = false,
    int? memoryKiB,
    int? iterations,
    int? parallelism,
  }) =>
      OnboardingState(
        step: step ?? this.step,
        isProcessing: isProcessing ?? this.isProcessing,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        memoryKiB: memoryKiB ?? this.memoryKiB,
        iterations: iterations ?? this.iterations,
        parallelism: parallelism ?? this.parallelism,
      );
}

// ─── Notifier ────────────────────────────────────────────────────────────────

@riverpod
class OnboardingNotifier extends _$OnboardingNotifier {
  @override
  OnboardingState build() => const OnboardingState();

  // ── Navigation ────────────────────────────────────────────────────────

  void goToStep(OnboardingStep step) =>
      state = state.copyWith(step: step, clearError: true);

  void nextStep() {
    final steps = OnboardingStep.values;
    final current = state.step.index;
    if (current < steps.length - 1) {
      state = state.copyWith(step: steps[current + 1], clearError: true);
    }
  }

  void previousStep() {
    final steps = OnboardingStep.values;
    final current = state.step.index;
    if (current > 0) {
      state = state.copyWith(step: steps[current - 1], clearError: true);
    }
  }

  // ── Master password setup ─────────────────────────────────────────────

  /// Derives Argon2id key, encrypts a sentinel value, persists VaultMetadataModel.
  /// On success, sets the session key and returns true.
  Future<bool> setMasterPassword(String password) async {
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password cannot be empty.');
      return false;
    }
    if (password.length < 8) {
      state = state.copyWith(
          errorMessage: 'Password must be at least 8 characters.');
      return false;
    }

    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      // 1. Derive key bundle (runs in isolate — does NOT block UI).
      final keyBundle = await KeyDerivation.deriveKey(
        password: password,
        memoryKiB: state.memoryKiB,
        iterations: state.iterations,
        parallelism: state.parallelism,
      );

      // 2. Encrypt a known sentinel so we can verify the password later.
      //    sentinel plaintext = 'SAFIRA_VAULT_V1'
      final sentinel = await CryptoEngine.encrypt(
        plaintext: Uint8List.fromList('SAFIRA_VAULT_V1'.codeUnits),
        key: keyBundle.derivedKey,
      );

      // 3. Persist metadata to Isar.
      final isar = await ref.read(databaseProvider.future);
      await isar.writeTxn(() async {
        final metadata = VaultMetadataModel(
          argon2Salt: keyBundle.salt,
          argon2MemoryKiB: state.memoryKiB,
          argon2Iterations: state.iterations,
          argon2Parallelism: state.parallelism,
          encryptedSentinel: sentinel.toStorageString(),
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
        );
        await isar.vaultMetadataModels.put(metadata);
      });

      // 4. Store derived key in SessionManager.
      final session = ref.read(sessionManagerProvider);
      session.unlock(keyBundle.derivedKey);

      // 5. Zero the bundle from memory.
      keyBundle.zero();

      state = state.copyWith(isProcessing: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to set master password: $e',
      );
      return false;
    }
  }

  // ── Complete onboarding ───────────────────────────────────────────────

  Future<void> completeOnboarding({
    bool biometricEnabled = false,
    int autoLockMinutes = 15,
    String themeName = 'system',
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true);
    try {
      final isar = await ref.read(databaseProvider.future);

      // Persist app settings.
      await isar.writeTxn(() async {
        final existing =
            await isar.appSettingsModels.where().findFirst();
        final settings = existing ??
            AppSettingsModel(
              createdAt: DateTime.now().toUtc(),
            );
        settings
          ..biometricEnabled = biometricEnabled
          ..autoLockMinutes = autoLockMinutes
          ..themeName = themeName
          ..updatedAt = DateTime.now().toUtc();
        await isar.appSettingsModels.put(settings);
      });

      // Mark as onboarded in secure storage via AppStateNotifier.
      await ref.read(appStateNotifierProvider.notifier).completeOnboarding();

      state = state.copyWith(
        isProcessing: false,
        step: OnboardingStep.done,
      );
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        errorMessage: 'Failed to complete onboarding: $e',
      );
    }
  }
}
