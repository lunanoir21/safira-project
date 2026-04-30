// lib/core/constants/app_constants.dart
// Application-wide constants for Safira (compile-time, zero runtime overhead).
library;

abstract final class AppConstants {
  static const String appName = 'Safira';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  static const String packageName = 'dev.safira.app';
  const AppConstants._();
}

/// Cryptographic constants — DO NOT change without migrating existing vaults.
abstract final class CryptoConstants {
  /// AES-256-GCM key length (bytes)
  static const int aesKeyLength = 32;

  /// AES-GCM nonce length (bytes — 96 bits, recommended for GCM)
  static const int aesNonceLength = 12;

  /// AES-GCM authentication tag length (bytes — 128 bits)
  static const int aesTagLength = 16;

  /// Argon2id salt length (bytes)
  static const int argon2SaltLength = 32;

  /// Argon2id memory cost (KiB — 64 MiB, exceeds OWASP minimum)
  static const int argon2MemoryKiB = 65536;

  /// Backward-compat alias
  static const int argon2Memory = argon2MemoryKiB;

  /// Argon2id iteration count
  static const int argon2Iterations = 3;

  /// Argon2id parallelism factor
  static const int argon2Parallelism = 4;

  /// Argon2id output key length (bytes — 256-bit AES key)
  static const int argon2KeyLength = 32;

  /// TOTP time step (seconds — RFC 6238)
  static const int totpTimeStep = 30;

  /// TOTP digits (RFC 6238 default)
  static const int totpDigits = 6;

  /// HIBP k-anonymity prefix length (SHA-1 hex chars)
  static const int hibpPrefixLength = 5;

  const CryptoConstants._();
}

/// Security & session constants.
abstract final class SecurityConstants {
  static const int maxFailedAttempts = 5;
  static const int backoffBaseSeconds = 2;
  static const int backoffMaxSeconds = 600;
  static const int defaultSessionTimeoutMinutes = 15;
  static const int defaultClipboardClearSeconds = 30;
  static const int minMasterPasswordLength = 8;
  static const int maxMasterPasswordLength = 512;
  const SecurityConstants._();
}

/// Database constants.
abstract final class DatabaseConstants {
  static const String isarDbName = 'safira';
  static const int isarSchemaVersion = 2; // bumped for SecureNoteModel
  const DatabaseConstants._();
}

/// UI / UX constants.
abstract final class UiConstants {
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 350);
  static const Duration animationDurationSlow = Duration(milliseconds: 600);
  static const Duration onboardingAnimDuration = Duration(milliseconds: 800);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration snackbarDuration = Duration(seconds: 3);
  static const Duration passwordRevealDuration = Duration(milliseconds: 150);

  static const double desktopMinWidth = 800;
  static const double desktopMinHeight = 600;
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;

  const UiConstants._();
}

/// Asset paths.
abstract final class AssetPaths {
  static const String animationsDir = 'assets/animations/';
  static const String iconsDir = 'assets/icons/';
  static const String imagesDir = 'assets/images/';

  static const String splashAnimation = '${animationsDir}splash.json';
  static const String lockAnimation = '${animationsDir}lock.json';
  static const String successAnimation = '${animationsDir}success.json';
  static const String emptyVaultAnimation = '${animationsDir}empty_vault.json';
  static const String shieldAnimation = '${animationsDir}shield.json';

  const AssetPaths._();
}

/// Route paths for go_router.
abstract final class RoutePaths {
  /// Loading gate (shown while AppState initialises from secure storage).
  static const String splash = '/';

  /// First-launch welcome screen (shown before onboarding).
  static const String welcome = '/welcome';

  static const String onboarding = '/onboarding';
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingMasterPassword = '/onboarding/master-password';
  static const String onboardingTheme = '/onboarding/theme';
  static const String onboardingBiometric = '/onboarding/biometric';

  static const String lock = '/lock';
  static const String dashboard = '/dashboard';
  static const String generator = '/generator';
  static const String totp = '/totp';
  static const String health = '/health';
  static const String secureNotes = '/secure-notes';
  static const String importExport = '/import-export';
  static const String settings = '/settings';

  const RoutePaths._();
}
