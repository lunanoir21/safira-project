import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/features/auth/presentation/pages/lock_page.dart';
import 'package:safira/features/onboarding/presentation/pages/onboarding_biometric_page.dart';
import 'package:safira/features/onboarding/presentation/pages/onboarding_master_password_page.dart';
import 'package:safira/features/onboarding/presentation/pages/onboarding_theme_page.dart';
import 'package:safira/features/onboarding/presentation/pages/onboarding_welcome_page.dart';
import 'package:safira/features/vault/presentation/pages/dashboard_page.dart';
import 'package:safira/features/vault/presentation/pages/vault_entry_page.dart';
import 'package:safira/features/vault/presentation/pages/vault_create_page.dart';
import 'package:safira/features/generator/presentation/pages/generator_page.dart';
import 'package:safira/features/totp/presentation/pages/totp_page.dart';
import 'package:safira/features/health/presentation/pages/health_page.dart';
import 'package:safira/features/settings/presentation/pages/settings_page.dart';
import 'package:safira/shared/providers/app_state_provider.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final appState = ref.watch(appStateProvider);

  return GoRouter(
    initialLocation: RoutePaths.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isOnboarded = appState.isOnboarded;
      final isUnlocked = appState.isUnlocked;
      final path = state.matchedLocation;

      // Not onboarded → force onboarding
      if (!isOnboarded && !path.startsWith('/onboarding')) {
        return RoutePaths.onboardingWelcome;
      }

      // Onboarded but locked → force lock screen
      if (isOnboarded && !isUnlocked && path != RoutePaths.lock) {
        return RoutePaths.lock;
      }

      // Already unlocked → redirect away from lock screen
      if (isUnlocked && path == RoutePaths.lock) {
        return RoutePaths.dashboard;
      }

      return null;
    },
    routes: [
      // Onboarding
      GoRoute(
        path: RoutePaths.onboardingWelcome,
        pageBuilder: (ctx, state) => _buildPage(
          state,
          const OnboardingWelcomePage(),
          transitionType: _TransitionType.fade,
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingMasterPassword,
        pageBuilder: (ctx, state) => _buildPage(
          state,
          const OnboardingMasterPasswordPage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingTheme,
        pageBuilder: (ctx, state) => _buildPage(
          state,
          const OnboardingThemePage(),
        ),
      ),
      GoRoute(
        path: RoutePaths.onboardingBiometric,
        pageBuilder: (ctx, state) => _buildPage(
          state,
          const OnboardingBiometricPage(),
        ),
      ),

      // Auth
      GoRoute(
        path: RoutePaths.lock,
        pageBuilder: (ctx, state) => _buildPage(
          state,
          const LockPage(),
          transitionType: _TransitionType.fade,
        ),
      ),

      // Main app
      GoRoute(
        path: RoutePaths.dashboard,
        pageBuilder: (ctx, state) => _buildPage(
          state,
          const DashboardPage(),
        ),
        routes: [
          GoRoute(
            path: 'vault/create',
            pageBuilder: (ctx, state) => _buildPage(
              state,
              const VaultCreatePage(),
              transitionType: _TransitionType.bottomSheet,
            ),
          ),
          GoRoute(
            path: 'vault/entry/:id',
            pageBuilder: (ctx, state) => _buildPage(
              state,
              VaultEntryPage(entryId: state.pathParameters['id']!),
            ),
          ),
        ],
      ),
      GoRoute(
        path: RoutePaths.generator,
        pageBuilder: (ctx, state) => _buildPage(state, const GeneratorPage()),
      ),
      GoRoute(
        path: RoutePaths.totp,
        pageBuilder: (ctx, state) => _buildPage(state, const TotpPage()),
      ),
      GoRoute(
        path: RoutePaths.health,
        pageBuilder: (ctx, state) => _buildPage(state, const HealthPage()),
      ),
      GoRoute(
        path: RoutePaths.settings,
        pageBuilder: (ctx, state) => _buildPage(state, const SettingsPage()),
      ),
    ],
    errorBuilder: (context, state) => _ErrorPage(error: state.error),
  );
}

enum _TransitionType { slide, fade, bottomSheet }

CustomTransitionPage<void> _buildPage(
  GoRouterState state,
  Widget child, {
  _TransitionType transitionType = _TransitionType.slide,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: UiConstants.pageTransitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      switch (transitionType) {
        case _TransitionType.fade:
          return FadeTransition(opacity: animation, child: child);
        case _TransitionType.bottomSheet:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        case _TransitionType.slide:
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
      }
    },
  );
}

class _ErrorPage extends StatelessWidget {
  const _ErrorPage({required this.error});
  final Exception? error;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Page not found', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.go(RoutePaths.dashboard),
                child: const Text('Go to Dashboard'),
              ),
            ],
          ),
        ),
      );
}
