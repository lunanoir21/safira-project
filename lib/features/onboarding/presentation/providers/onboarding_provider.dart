import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safira/core/security/key_derivation.dart';

part 'onboarding_provider.g.dart';

/// Manages onboarding state and key derivation.
@riverpod
class Onboarding extends _$Onboarding {
  @override
  OnboardingState build() => const OnboardingState();

  /// Derives keys from master password and stores vault metadata.
  Future<void> setMasterPassword(String masterPassword) async {
    state = state.copyWith(isDerivingKey: true, error: null);

    try {
      final bundle = await KeyDerivation.instance.deriveKeyBundle(
        masterPassword: masterPassword,
      );

      // TODO: Persist keySalt, verificationHash, verificationSalt to Isar
      // TODO: Store encryptionKey in SessionManager (in-memory only)

      state = state.copyWith(
        isDerivingKey: false,
        masterPasswordSet: true,
      );

      // Zero out the key bundle after use
      bundle.dispose();
    } on Exception catch (e) {
      state = state.copyWith(
        isDerivingKey: false,
        error: e.toString(),
      );
      rethrow;
    }
  }
}

/// Immutable onboarding state.
class OnboardingState {
  const OnboardingState({
    this.isDerivingKey = false,
    this.masterPasswordSet = false,
    this.biometricEnabled = false,
    this.error,
  });

  final bool isDerivingKey;
  final bool masterPasswordSet;
  final bool biometricEnabled;
  final String? error;

  OnboardingState copyWith({
    bool? isDerivingKey,
    bool? masterPasswordSet,
    bool? biometricEnabled,
    String? error,
  }) =>
      OnboardingState(
        isDerivingKey: isDerivingKey ?? this.isDerivingKey,
        masterPasswordSet: masterPasswordSet ?? this.masterPasswordSet,
        biometricEnabled: biometricEnabled ?? this.biometricEnabled,
        error: error,
      );
}
