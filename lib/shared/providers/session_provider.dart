// lib/shared/providers/session_provider.dart
// Bridges SessionManager (ChangeNotifier) into Riverpod and reacts to lock events.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/session/session_manager.dart';
import 'app_state_provider.dart';

part 'session_provider.g.dart';

// ─── Singleton SessionManager ─────────────────────────────────────────────────

@Riverpod(keepAlive: true)
SessionManager sessionManager(SessionManagerRef ref) {
  final manager = SessionManager();

  // When the session locks, propagate the locked state to AppStateNotifier.
  manager.addListener(() {
    if (manager.isLocked) {
      ref.read(appStateNotifierProvider.notifier).lock();
    }
  });

  ref.onDispose(() {
    manager.dispose();
  });

  return manager;
}

// ─── Convenience: is the session currently unlocked? ─────────────────────────

@riverpod
bool isSessionUnlocked(IsSessionUnlockedRef ref) {
  // Re-compute whenever AppState changes (avoids polling SessionManager directly).
  return ref.watch(appStateNotifierProvider).isUnlocked;
}
