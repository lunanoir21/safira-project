import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/errors/failures.dart';
import 'package:safira/features/auth/presentation/providers/auth_provider.dart';
import 'package:safira/shared/widgets/safira_button.dart';
import 'package:safira/shared/widgets/safira_text_field.dart';

/// Lock screen — shown when the vault is locked.
///
/// Supports:
/// - Master password unlock
/// - Biometric unlock (if configured)
/// - Exponential backoff on failed attempts
/// - Clear error messaging
class LockPage extends ConsumerStatefulWidget {
  const LockPage({super.key});

  @override
  ConsumerState<LockPage> createState() => _LockPageState();
}

class _LockPageState extends ConsumerState<LockPage> {
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    // Auto-attempt biometric on page load
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryBiometric());
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (_, next) {
      if (next.isUnlocked) context.go(RoutePaths.dashboard);
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Lock icon with animation
                Icon(
                  Icons.lock_outline_rounded,
                  size: 72,
                  color: colorScheme.primary,
                )
                    .animate(
                      onPlay: (c) => c.repeat(reverse: true),
                    )
                    .shimmer(
                      duration: 2000.ms,
                      color: colorScheme.primary.withOpacity(0.3),
                    ),

                const SizedBox(height: 24),

                Text(
                  AppConstants.appName,
                  style: textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  'Enter your master password to unlock',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // Failed attempts warning
                if (authState.failedAttempts > 0)
                  _FailedAttemptsWarning(
                    attempts: authState.failedAttempts,
                    lockoutSeconds: authState.lockoutRemainingSeconds,
                  ).animate().shake(),

                const SizedBox(height: 16),

                // Password field
                SafiraTextField(
                  controller: _passwordController,
                  label: 'Master Password',
                  isPassword: true,
                  autofocus: true,
                  enabled: !authState.isLoading && authState.lockoutRemainingSeconds == 0,
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: authState.error,
                  onSubmitted: (_) => _unlock(),
                ),

                const SizedBox(height: 24),

                // Unlock button
                SafiraButton(
                  label: authState.lockoutRemainingSeconds > 0
                      ? 'Wait ${authState.lockoutRemainingSeconds}s'
                      : 'Unlock',
                  icon: Icons.lock_open_rounded,
                  isLoading: authState.isLoading,
                  onPressed: authState.lockoutRemainingSeconds > 0 || authState.isLoading
                      ? null
                      : _unlock,
                ),

                const SizedBox(height: 16),

                // Biometric button
                if (authState.biometricAvailable)
                  SafiraButton(
                    label: 'Use Biometrics',
                    icon: Icons.fingerprint,
                    variant: SafiraButtonVariant.outlined,
                    onPressed: _tryBiometric,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _unlock() async {
    if (_passwordController.text.isEmpty) return;
    await ref
        .read(authProvider.notifier)
        .unlockWithPassword(_passwordController.text);
    _passwordController.clear();
  }

  Future<void> _tryBiometric() async {
    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock Safira',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
      if (didAuthenticate && mounted) {
        await ref.read(authProvider.notifier).unlockWithBiometric();
      }
    } on Exception {
      // Biometric failed silently — user can use password
    }
  }
}

class _FailedAttemptsWarning extends StatelessWidget {
  const _FailedAttemptsWarning({
    required this.attempts,
    required this.lockoutSeconds,
  });

  final int attempts;
  final int lockoutSeconds;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(UiConstants.radiusMedium),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lockoutSeconds > 0
                    ? 'Too many failed attempts. Wait ${lockoutSeconds}s.'
                    : '$attempts failed attempt${attempts > 1 ? 's' : ''}. '
                        '${SecurityConstants.maxFailedAttempts - attempts} remaining.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ],
        ),
      );
}
