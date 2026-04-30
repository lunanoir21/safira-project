import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/shared/providers/app_state_provider.dart';
import 'package:safira/shared/providers/session_provider.dart';

part 'auth_provider.g.dart';

/// Auth provider with brute-force protection and session management.
@riverpod
class Auth extends _$Auth {
  Timer? _lockoutTimer;

  @override
  AuthState build() => const AuthState();

  /// Attempts to unlock the vault with [password].
  ///
  /// Implements exponential backoff after [SecurityConstants.maxFailedAttempts].
  Future<void> unlockWithPassword(String password) async {
    if (state.lockoutRemainingSeconds > 0) return;

    state = state.copyWith(isLoading: true, error: null);

    // Simulate Argon2id derivation delay (replaced by real KDF in production)
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Verify password against stored verificationHash via KeyDerivation
    // For now, simulate verification
    final isCorrect = password.isNotEmpty; // Placeholder

    if (isCorrect) {
      _onUnlockSuccess();
    } else {
      _onUnlockFailure();
    }
  }

  /// Unlocks using biometric (session key retrieved from secure storage).
  Future<void> unlockWithBiometric() async {
    state = state.copyWith(isLoading: true, error: null);

    // TODO: Retrieve wrapped key from Android Keystore / Linux keyring
    await Future.delayed(const Duration(milliseconds: 300));

    _onUnlockSuccess();
  }

  void _onUnlockSuccess() {
    _lockoutTimer?.cancel();
    // TODO: Call sessionManager.unlock(derivedKey)
    ref.read(appStateProvider.notifier).setUnlocked(true);
    state = const AuthState(isUnlocked: true);
  }

  void _onUnlockFailure() {
    final newAttempts = state.failedAttempts + 1;
    var lockoutSeconds = 0;

    if (newAttempts >= SecurityConstants.maxFailedAttempts) {
      // Exponential backoff: 2^(attempts - maxAttempts) seconds, capped
      lockoutSeconds = min(
        SecurityConstants.backoffBaseSeconds *
            pow(2, newAttempts - SecurityConstants.maxFailedAttempts).toInt(),
        SecurityConstants.backoffMaxSeconds,
      );
      _startLockoutTimer(lockoutSeconds);
    }

    state = state.copyWith(
      isLoading: false,
      failedAttempts: newAttempts,
      lockoutRemainingSeconds: lockoutSeconds,
      error: newAttempts >= SecurityConstants.maxFailedAttempts
          ? null // Error shown via lockout UI
          : 'Incorrect password — ${SecurityConstants.maxFailedAttempts - newAttempts} attempts remaining',
    );
  }

  void _startLockoutTimer(int seconds) {
    _lockoutTimer?.cancel();
    var remaining = seconds;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining--;
      state = state.copyWith(lockoutRemainingSeconds: remaining);
      if (remaining <= 0) {
        timer.cancel();
        state = state.copyWith(lockoutRemainingSeconds: 0, error: null);
      }
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }
}

/// Immutable auth state.
class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isUnlocked = false,
    this.failedAttempts = 0,
    this.lockoutRemainingSeconds = 0,
    this.biometricAvailable = true,
    this.error,
  });

  final bool isLoading;
  final bool isUnlocked;
  final int failedAttempts;
  final int lockoutRemainingSeconds;
  final bool biometricAvailable;
  final String? error;

  AuthState copyWith({
    bool? isLoading,
    bool? isUnlocked,
    int? failedAttempts,
    int? lockoutRemainingSeconds,
    bool? biometricAvailable,
    String? error,
  }) =>
      AuthState(
        isLoading: isLoading ?? this.isLoading,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        failedAttempts: failedAttempts ?? this.failedAttempts,
        lockoutRemainingSeconds: lockoutRemainingSeconds ?? this.lockoutRemainingSeconds,
        biometricAvailable: biometricAvailable ?? this.biometricAvailable,
        error: error,
      );
}
