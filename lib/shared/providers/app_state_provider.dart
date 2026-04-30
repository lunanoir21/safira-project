// lib/shared/providers/app_state_provider.dart
// Central app state: onboarding status, lock state, theme — with flutter_secure_storage persistence.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_state_provider.g.dart';

// ─── Storage key constants ───────────────────────────────────────────────────

const _kIsOnboarded = 'safira_is_onboarded';

// ─── Secure storage singleton ────────────────────────────────────────────────

const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  lOptions: LinuxOptions(),
);

// ─── App State ───────────────────────────────────────────────────────────────

class AppState {
  final bool isOnboarded;
  final bool isUnlocked;
  final bool isLoading;

  const AppState({
    this.isOnboarded = false,
    this.isUnlocked = false,
    this.isLoading = true,
  });

  AppState copyWith({
    bool? isOnboarded,
    bool? isUnlocked,
    bool? isLoading,
  }) =>
      AppState(
        isOnboarded: isOnboarded ?? this.isOnboarded,
        isUnlocked: isUnlocked ?? this.isUnlocked,
        isLoading: isLoading ?? this.isLoading,
      );

  @override
  String toString() =>
      'AppState(onboarded=$isOnboarded, unlocked=$isUnlocked, loading=$isLoading)';
}

// ─── Provider ────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
class AppStateNotifier extends _$AppStateNotifier {
  @override
  AppState build() {
    // Kick off async initialisation without blocking the synchronous build.
    _init();
    return const AppState(isLoading: true);
  }

  // ── Initialisation ──────────────────────────────────────────────────────

  Future<void> _init() async {
    try {
      final onboardedStr = await _storage.read(key: _kIsOnboarded);
      final isOnboarded = onboardedStr == 'true';
      state = state.copyWith(
        isOnboarded: isOnboarded,
        isUnlocked: false,
        isLoading: false,
      );
    } catch (e) {
      // If secure storage fails (e.g. fresh Linux install), treat as not onboarded.
      state = state.copyWith(
        isOnboarded: false,
        isUnlocked: false,
        isLoading: false,
      );
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────

  /// Called after onboarding is complete.
  Future<void> completeOnboarding() async {
    await _storage.write(key: _kIsOnboarded, value: 'true');
    state = state.copyWith(isOnboarded: true);
  }

  /// Called when the user successfully unlocks the vault.
  void setUnlocked({required bool unlocked}) {
    state = state.copyWith(isUnlocked: unlocked);
  }

  /// Called when session times out or user manually locks.
  Future<void> lock() async {
    state = state.copyWith(isUnlocked: false);
  }

  /// Full reset — clears onboarding flag (for "wipe & reset" feature).
  Future<void> reset() async {
    await _storage.deleteAll();
    state = const AppState(isOnboarded: false, isUnlocked: false, isLoading: false);
  }
}
