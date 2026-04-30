import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Safira's Material 3 theme system.
///
/// Provides light, dark, and custom seed-based themes using FlexColorScheme
/// for advanced Material 3 color system generation.
abstract final class AppTheme {
  // ─── Default Seed Color ───────────────────────────────────────────────────

  static const Color _defaultSeedColor = Color(0xFF6750A4); // M3 baseline purple

  // ─── Text Theme ───────────────────────────────────────────────────────────

  static TextTheme _buildTextTheme(TextTheme base) =>
      GoogleFonts.interTextTheme(base);

  // ─── Light Theme ──────────────────────────────────────────────────────────

  static ThemeData light({Color? seedColor}) {
    final seed = seedColor ?? _defaultSeedColor;
    return FlexThemeData.light(
      scheme: FlexScheme.materialBaseline,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 7,
      subThemesData: _subThemes(),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      textTheme: _buildTextTheme(ThemeData.light().textTheme),
      primaryTextTheme: _buildTextTheme(ThemeData.light().primaryTextTheme),
    );
  }

  // ─── Dark Theme ───────────────────────────────────────────────────────────

  static ThemeData dark({Color? seedColor}) {
    final seed = seedColor ?? _defaultSeedColor;
    return FlexThemeData.dark(
      scheme: FlexScheme.materialBaseline,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.dark,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 13,
      subThemesData: _subThemes(),
      visualDensity: FlexColorScheme.comfortablePlatformDensity,
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      textTheme: _buildTextTheme(ThemeData.dark().textTheme),
      primaryTextTheme: _buildTextTheme(ThemeData.dark().primaryTextTheme),
    );
  }

  // ─── Sub-themes ───────────────────────────────────────────────────────────

  static FlexSubThemesData _subThemes() => const FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: false,
        inputDecoratorIsFilled: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorBorderRadius: 12,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorPrefixIconSchemeColor: SchemeColor.primary,
        cardRadius: 16,
        dialogRadius: 20,
        bottomSheetRadius: 24,
        elevatedButtonRadius: 12,
        filledButtonRadius: 12,
        outlinedButtonRadius: 12,
        textButtonRadius: 12,
        segmentedButtonRadius: 12,
        chipRadius: 8,
        snackBarRadius: 12,
        fabRadius: 16,
        navigationBarSelectedLabelSchemeColor: SchemeColor.primary,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
        navigationBarIndicatorSchemeColor: SchemeColor.secondaryContainer,
        navigationRailSelectedLabelSchemeColor: SchemeColor.primary,
        navigationRailSelectedIconSchemeColor: SchemeColor.primary,
        navigationRailIndicatorSchemeColor: SchemeColor.secondaryContainer,
      );
}

/// Theme mode enum with a custom option for seed-based theming.
enum SafiraThemeMode {
  light,
  dark,
  system,
  custom;

  ThemeMode get flutterThemeMode => switch (this) {
        SafiraThemeMode.light => ThemeMode.light,
        SafiraThemeMode.dark => ThemeMode.dark,
        SafiraThemeMode.system => ThemeMode.system,
        SafiraThemeMode.custom => ThemeMode.light, // overridden by seed
      };

  String get displayName => switch (this) {
        SafiraThemeMode.light => 'Light',
        SafiraThemeMode.dark => 'Dark',
        SafiraThemeMode.system => 'System',
        SafiraThemeMode.custom => 'Custom',
      };

  IconData get icon => switch (this) {
        SafiraThemeMode.light => Icons.light_mode_outlined,
        SafiraThemeMode.dark => Icons.dark_mode_outlined,
        SafiraThemeMode.system => Icons.brightness_auto_outlined,
        SafiraThemeMode.custom => Icons.palette_outlined,
      };
}
