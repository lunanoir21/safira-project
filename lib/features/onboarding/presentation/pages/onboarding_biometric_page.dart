import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/shared/widgets/safira_button.dart';

/// Biometric authentication setup page — final onboarding step.
class OnboardingBiometricPage extends ConsumerStatefulWidget {
  const OnboardingBiometricPage({super.key});

  @override
  ConsumerState<OnboardingBiometricPage> createState() =>
      _OnboardingBiometricPageState();
}

class _OnboardingBiometricPageState
    extends ConsumerState<OnboardingBiometricPage> {
  final _localAuth = LocalAuthentication();
  bool? _isBiometricAvailable;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final biometrics = canCheck ? await _localAuth.getAvailableBiometrics() : <BiometricType>[];

      setState(() {
        _isBiometricAvailable = canCheck && isDeviceSupported;
        _availableBiometrics = biometrics;
      });
    } on Exception {
      setState(() => _isBiometricAvailable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(RoutePaths.onboardingTheme)),
        title: const Text('Biometric Setup'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress
              LinearProgressIndicator(
                value: 1.0,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quick unlock',
                      style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use biometrics to unlock Safira quickly — your master password is still required for vault encryption.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Biometric icon
                    Center(
                      child: _BiometricIcon(
                        types: _availableBiometrics,
                        color: colorScheme.primary,
                        enabled: _biometricEnabled,
                      ).animate().scale(
                            begin: const Offset(0.5, 0.5),
                            duration: 600.ms,
                            curve: Curves.elasticOut,
                          ),
                    ),

                    const SizedBox(height: 32),

                    if (_isBiometricAvailable == null)
                      const Center(child: CircularProgressIndicator())
                    else if (_isBiometricAvailable == false)
                      _UnavailableCard()
                    else ...[
                      // Enable switch
                      Card(
                        child: SwitchListTile(
                          title: Text(
                            'Enable Biometric Unlock',
                            style: textTheme.titleSmall,
                          ),
                          subtitle: Text(
                            _getSubtitle(),
                            style: textTheme.bodySmall,
                          ),
                          value: _biometricEnabled,
                          onChanged: _isBiometricAvailable!
                              ? (v) => setState(() => _biometricEnabled = v)
                              : null,
                          secondary: Icon(
                            _getIcon(),
                            color: colorScheme.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(UiConstants.radiusLarge),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Buttons
              Column(
                children: [
                  if (_biometricEnabled)
                    SafiraButton(
                      label: 'Enable & Finish',
                      icon: Icons.check_rounded,
                      isLoading: _isLoading,
                      onPressed: _finish,
                    )
                  else
                    SafiraButton(
                      label: 'Skip for Now',
                      variant: SafiraButtonVariant.outlined,
                      onPressed: _finish,
                    ),
                  const SizedBox(height: 8),
                  if (_biometricEnabled)
                    SafiraButton(
                      label: 'Skip for Now',
                      variant: SafiraButtonVariant.text,
                      onPressed: () => _finishWithoutBiometric(),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) context.go(RoutePaths.dashboard);
  }

  void _finishWithoutBiometric() => context.go(RoutePaths.dashboard);

  String _getSubtitle() {
    if (_availableBiometrics.contains(BiometricType.face)) return 'Face ID';
    if (_availableBiometrics.contains(BiometricType.fingerprint)) return 'Fingerprint';
    return 'Device biometrics';
  }

  IconData _getIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) return Icons.face_outlined;
    return Icons.fingerprint;
  }
}

class _BiometricIcon extends StatelessWidget {
  const _BiometricIcon({
    required this.types,
    required this.color,
    required this.enabled,
  });

  final List<BiometricType> types;
  final Color color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final icon = types.contains(BiometricType.face)
        ? Icons.face_outlined
        : Icons.fingerprint;

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: enabled ? color.withOpacity(0.15) : Colors.grey.withOpacity(0.1),
        border: Border.all(
          color: enabled ? color : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: Icon(
        icon,
        size: 60,
        color: enabled ? color : Colors.grey,
      ),
    );
  }
}

class _UnavailableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Theme.of(context).colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Biometric authentication is not available on this device.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      );
}
