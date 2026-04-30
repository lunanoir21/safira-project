import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/features/onboarding/presentation/providers/onboarding_provider.dart';
import 'package:safira/shared/widgets/safira_button.dart';
import 'package:safira/shared/widgets/safira_text_field.dart';

/// Master password creation page.
///
/// Security requirements enforced:
/// - Minimum 12 characters
/// - Confirmation must match
/// - Strength indicator with entropy calculation
/// - Clear explanation of zero-knowledge model
class OnboardingMasterPasswordPage extends ConsumerStatefulWidget {
  const OnboardingMasterPasswordPage({super.key});

  @override
  ConsumerState<OnboardingMasterPasswordPage> createState() =>
      _OnboardingMasterPasswordPageState();
}

class _OnboardingMasterPasswordPageState
    extends ConsumerState<OnboardingMasterPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(RoutePaths.onboardingWelcome)),
        title: const Text('Master Password'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress
                LinearProgressIndicator(
                  value: 0.33,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 24),

                // Header
                Text('Create your master password',
                    style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'This is the only password you need to remember. '
                  'It encrypts all your data using AES-256-GCM + Argon2id. '
                  'We never store it — if you lose it, your data cannot be recovered.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                // Warning card
                _SecurityWarningCard(),
                const SizedBox(height: 24),

                // Password field
                SafiraTextField(
                  controller: _passwordController,
                  label: 'Master Password',
                  hint: 'At least 12 characters',
                  isPassword: true,
                  showStrengthIndicator: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  onChanged: (_) => setState(() => _errorText = null),
                ),
                const SizedBox(height: 16),

                // Confirm field
                SafiraTextField(
                  controller: _confirmController,
                  label: 'Confirm Master Password',
                  hint: 'Repeat your password',
                  isPassword: true,
                  prefixIcon: const Icon(Icons.lock_outline),
                  errorText: _errorText,
                  onChanged: (_) => setState(() => _errorText = null),
                  onSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 32),

                // Requirements checklist
                _PasswordRequirements(password: _passwordController.text),
                const SizedBox(height: 32),

                // Continue button
                SafiraButton(
                  label: 'Continue',
                  icon: Icons.arrow_forward_rounded,
                  isLoading: _isLoading,
                  onPressed: _canSubmit() ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _canSubmit() =>
      _passwordController.text.length >= SecurityConstants.minMasterPasswordLength &&
      !_isLoading;

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() => _errorText = 'Passwords do not match');
      return;
    }

    if (_passwordController.text.length < SecurityConstants.minMasterPasswordLength) {
      setState(() =>
          _errorText = 'Password must be at least ${SecurityConstants.minMasterPasswordLength} characters');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(onboardingProvider.notifier)
          .setMasterPassword(_passwordController.text);

      if (mounted) context.go(RoutePaths.onboardingTheme);
    } on Exception catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorText = e.toString();
        });
      }
    }
  }
}

class _SecurityWarningCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(UiConstants.radiusMedium),
          border: Border.all(
            color: Theme.of(context).colorScheme.error.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Theme.of(context).colorScheme.error,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'There is no password recovery. Write it down and store it safely.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      );
}

class _PasswordRequirements extends StatefulWidget {
  const _PasswordRequirements({required this.password});
  final String password;

  @override
  State<_PasswordRequirements> createState() => _PasswordRequirementsState();
}

class _PasswordRequirementsState extends State<_PasswordRequirements> {
  @override
  Widget build(BuildContext context) {
    final requirements = [
      (
        'At least ${SecurityConstants.minMasterPasswordLength} characters',
        widget.password.length >= SecurityConstants.minMasterPasswordLength,
      ),
      (
        'Contains uppercase letter',
        widget.password.contains(RegExp(r'[A-Z]')),
      ),
      (
        'Contains lowercase letter',
        widget.password.contains(RegExp(r'[a-z]')),
      ),
      (
        'Contains number',
        widget.password.contains(RegExp(r'[0-9]')),
      ),
      (
        'Contains special character',
        widget.password.contains(RegExp(r'[!@#\$%^&*]')),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: requirements
          .map(
            (r) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Icon(
                    r.$2 ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 18,
                    color: r.$2
                        ? Colors.green.shade600
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    r.$1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: r.$2
                              ? Colors.green.shade600
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
