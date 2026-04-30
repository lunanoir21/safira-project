import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safira/core/session/session_manager.dart';

part 'session_provider.g.dart';

/// Provides the singleton [SessionManager].
///
/// keepAlive: true — session must persist across route changes.
@Riverpod(keepAlive: true)
SessionManager sessionManager(SessionManagerRef ref) {
  final manager = SessionManager();
  ref.onDispose(manager.dispose);
  return manager;
}

/// Convenience provider: is the vault currently unlocked?
@riverpod
bool isVaultUnlocked(IsVaultUnlockedRef ref) {
  final session = ref.watch(sessionManagerProvider);
  // Listen to ChangeNotifier
  session.addListener(() => ref.invalidateSelf());
  return session.isUnlocked;
}
