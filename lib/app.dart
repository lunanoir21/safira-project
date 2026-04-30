import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'shared/providers/session_provider.dart';

/// Root widget for the Safira app.
///
/// Wires together:
///   - [AppRouter] (go_router with auth guards)
///   - [AppTheme] (Material 3, FlexColorScheme)
///   - [SessionManager] (auto-lock via [sessionProvider])
class SafiraApp extends ConsumerWidget {
  const SafiraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'Safira',
      debugShowCheckedModeBanner: false,

      // ── Theme ──────────────────────────────────────────────────
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode.toMaterialThemeMode(),

      // ── Routing ────────────────────────────────────────────────
      routerConfig: router,

      // ── Localizations ──────────────────────────────────────────
      // TODO: Add flutter_localizations + intl when i18n is needed
    );
  }
}

// ── Provider: theme mode ─────────────────────────────────────────────────────

final themeModeProvider =
    StateProvider<SafiraThemeMode>((ref) => SafiraThemeMode.system);

// ── Extension: convert SafiraThemeMode → Material ThemeMode ─────────────────

extension on SafiraThemeMode {
  ThemeMode toMaterialThemeMode() {
    switch (this) {
      case SafiraThemeMode.light:
        return ThemeMode.light;
      case SafiraThemeMode.dark:
        return ThemeMode.dark;
      case SafiraThemeMode.system:
        return ThemeMode.system;
    }
  }
}
