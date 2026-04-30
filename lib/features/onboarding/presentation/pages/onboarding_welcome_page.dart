import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/shared/widgets/safira_button.dart';

/// Animated welcome page — first screen users see.
///
/// Features a shield animation, app name reveal, and tagline,
/// followed by a CTA button to start setup.
class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Shield icon with glow
              _ShieldHero(color: colorScheme.primary),

              const SizedBox(height: 40),

              // App name
              Text(
                AppConstants.appName,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      letterSpacing: 2,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 400.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const SizedBox(height: 12),

              // Tagline
              Text(
                'Your passwords, secured.\nZero-knowledge. Offline-first.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
              )
                  .animate()
                  .fadeIn(delay: 700.ms, duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),

              const Spacer(flex: 2),

              // Feature pills
              _FeaturePills()
                  .animate()
                  .fadeIn(delay: 1000.ms, duration: 600.ms),

              const Spacer(),

              // CTA Button
              SafiraButton(
                label: 'Get Started',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go(RoutePaths.onboardingMasterPassword),
              )
                  .animate()
                  .fadeIn(delay: 1300.ms, duration: 500.ms)
                  .slideY(begin: 0.5, end: 0),

              const SizedBox(height: 16),

              Text(
                'No account needed. No cloud. No tracking.',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 1600.ms),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShieldHero extends StatefulWidget {
  const _ShieldHero({required this.color});
  final Color color;

  @override
  State<_ShieldHero> createState() => _ShieldHeroState();
}

class _ShieldHeroState extends State<_ShieldHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (_, child) => Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        ),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.2),
                widget.color.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Icon(
            Icons.shield_rounded,
            size: 80,
            color: widget.color,
          ),
        ),
      )
          .animate()
          .scale(
            begin: const Offset(0.3, 0.3),
            end: const Offset(1, 1),
            duration: 800.ms,
            curve: Curves.elasticOut,
          )
          .fadeIn(duration: 400.ms);
}

class _FeaturePills extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const features = [
      (Icons.lock_outline, 'AES-256-GCM'),
      (Icons.fingerprint, 'Biometric'),
      (Icons.wifi_off_outlined, 'Offline'),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: features
          .map(
            (f) => Chip(
              avatar: Icon(f.$1, size: 16),
              label: Text(f.$2),
              side: BorderSide.none,
            ),
          )
          .toList(),
    );
  }
}
