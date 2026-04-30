import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/theme/app_theme.dart';
import 'package:safira/shared/widgets/safira_button.dart';

/// Theme selection page with live preview.
class OnboardingThemePage extends ConsumerStatefulWidget {
  const OnboardingThemePage({super.key});

  @override
  ConsumerState<OnboardingThemePage> createState() => _OnboardingThemePageState();
}

class _OnboardingThemePageState extends ConsumerState<OnboardingThemePage> {
  SafiraThemeMode _selectedMode = SafiraThemeMode.system;
  Color _selectedSeedColor = const Color(0xFF6750A4);

  static const _seedColors = [
    Color(0xFF6750A4), // Purple (default)
    Color(0xFF006874), // Teal
    Color(0xFF006E1C), // Green
    Color(0xFFB3261E), // Red
    Color(0xFF006495), // Blue
    Color(0xFF7D5260), // Pink
    Color(0xFFE8700A), // Orange
    Color(0xFF006A6A), // Cyan
  ];

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go(RoutePaths.onboardingMasterPassword)),
        title: const Text('Choose Theme'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress
                    LinearProgressIndicator(
                      value: 0.66,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 24),

                    Text('Pick your style',
                        style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'Choose how Safira looks. You can change this anytime in Settings.',
                      style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 24),

                    // Theme mode cards
                    Text('Appearance', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.4,
                      children: SafiraThemeMode.values
                          .map((mode) => _ThemeModeCard(
                                mode: mode,
                                isSelected: _selectedMode == mode,
                                onTap: () => setState(() => _selectedMode = mode),
                              ))
                          .toList(),
                    ),

                    const SizedBox(height: 24),

                    // Seed color picker
                    Text('Accent Color', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _seedColors
                          .map(
                            (color) => GestureDetector(
                              onTap: () => setState(() {
                                _selectedSeedColor = color;
                                if (_selectedMode != SafiraThemeMode.custom) {
                                  _selectedMode = SafiraThemeMode.custom;
                                }
                              }),
                              child: AnimatedContainer(
                                duration: UiConstants.animationDurationFast,
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _selectedSeedColor == color
                                        ? colorScheme.onSurface
                                        : Colors.transparent,
                                    width: 3,
                                  ),
                                  boxShadow: _selectedSeedColor == color
                                      ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 8)]
                                      : null,
                                ),
                                child: _selectedSeedColor == color
                                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                                    : null,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: SafiraButton(
                label: 'Continue',
                icon: Icons.arrow_forward_rounded,
                onPressed: () => context.go(RoutePaths.onboardingBiometric),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  final SafiraThemeMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: UiConstants.animationDurationFast,
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(UiConstants.radiusLarge),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              mode.icon,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              mode.displayName,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
