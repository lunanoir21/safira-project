import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_state_provider.g.dart';

/// Global application state — drives routing decisions.
@riverpod
class AppState extends _$AppState {
  @override
  AppStateData build() => const AppStateData();

  void setOnboarded(bool value) =>
      state = state.copyWith(isOnboarded: value);

  void setUnlocked(bool value) =>
      state = state.copyWith(isUnlocked: value);

  void lock() => state = state.copyWith(isUnlocked: false);
}

/// Immutable app state data.
class AppStateData {
  const AppStateData({
    this.isOnboarded = false,
    this.isUnlocked = false,
  });

  final bool isOnboarded;
  final bool isUnlocked;

  AppStateData copyWith({
    bool? isOnboarded,
    bool? isUnlocked,
  }) =>
      AppStateData(
        isOnboarded: isOnboarded ?? this.isOnboarded,
        isUnlocked: isUnlocked ?? this.isUnlocked,
      );
}
