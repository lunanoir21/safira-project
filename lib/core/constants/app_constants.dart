/// Application-wide constants for Safira.
/// All values are compile-time constants for zero runtime overhead.
library;

/// Core application metadata
abstract final class AppConstants {
  static const String appName = 'Safira';
  static const String appVersion = '1.0.0';
  static const int appBuildNumber = 1;
  static const String packageName = 'dev.safira.app';

  // Prevent instantiation
  const AppConstants._();
}

/// Cryptographic constants — DO NOT change without migrating existing vaults
abstract final class CryptoConstants {
  /// AES-256-GCM key length in bytes
  static const int aesKeyLength = 32;

  /// AES-GCM nonce length in bytes (96 bits — recommended for GCM)
  static const int aesNonceLength = 12;

  /// AES-GCM authentication tag length in bytes (128 bits — maximum security)
  static const int aesTagLength = 16;

  /// Argon2id salt length in bytes
  static const int argon2SaltLength = 32;

  /// Argon2id memory cost in KiB (64 MB — OWASP recommended minimum)
  static const int argon2Memory = 65536;

  /// Argon2id iteration count
  static const int argon2Iterations = 3;

  /// Argon2id parallelism factor
  static const int argon2Parallelism = 4;

  /// Argon2id output key length in bytes
  static const int argon2KeyLength = 32;

  /// Verification hash length (separate from encryption key)
  static const int verificationHashLength = 32;

  /// TOTP time step in seconds (RFC 6238)
  static const int totpTimeStep = 30;

  /// TOTP digits (RFC 6238 default)
  static const int totpDigits = 6;

  /// HaveIBeenPwned k-anonymity prefix length (SHA-1 hex chars)
  static const int hibpPrefixLength = 5;

  const CryptoConstants._();
}

/// Security & session constants
abstract final class SecurityConstants {
  /// Max failed unlock attempts before exponential backoff kicks in
  static const int maxFailedAttempts = 5;

  /// Base delay in seconds for exponential backoff
  static const int backoffBaseSeconds = 2;

  /// Maximum backoff delay in seconds (10 minutes)
  static const int backoffMaxSeconds = 600;

  /// Default session timeout in minutes
  static const int defaultSessionTimeoutMinutes = 5;

  /// Default clipboard clear delay in seconds
  static const int defaultClipboardClearSeconds = 30;

  /// Minimum master password length
  static const int minMasterPasswordLength = 12;

  /// Maximum master password length (prevent DoS via huge KDF input)
  static const int maxMasterPasswordLength = 512;

  const SecurityConstants._();
}

/// Database constants
abstract final class DatabaseConstants {
  static const String isarDbName = 'safira_vault';
  static const int isarSchemaVersion = 1;

  const DatabaseConstants._();
}

/// UI / UX constants
abstract final class UiConstants {
  /// Default animation duration
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 350);
  static const Duration animationDurationSlow = Duration(milliseconds: 600);

  /// Onboarding animation duration
  static const Duration onboardingAnimDuration = Duration(milliseconds: 800);

  /// Page transition duration
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);

  /// Snackbar duration
  static const Duration snackbarDuration = Duration(seconds: 3);

  /// Password card reveal duration
  static const Duration passwordRevealDuration = Duration(milliseconds: 150);

  /// Desktop window minimum size
  static const double desktopMinWidth = 800;
  static const double desktopMinHeight = 600;

  /// Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Border radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;

  const UiConstants._();
}

/// Asset paths
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

/// Route paths for go_router
abstract final class RoutePaths {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String onboardingWelcome = '/onboarding/welcome';
  static const String onboardingMasterPassword = '/onboarding/master-password';
  static const String onboardingTheme = '/onboarding/theme';
  static const String onboardingBiometric = '/onboarding/biometric';
  static const String lock = '/lock';
  static const String dashboard = '/dashboard';
  static const String vaultEntry = '/vault/entry/:id';
  static const String vaultCreate = '/vault/create';
  static const String generator = '/generator';
  static const String totp = '/totp';
  static const String health = '/health';
  static const String secureNotes = '/secure-notes';
  static const String importExport = '/import-export';
  static const String settings = '/settings';

  const RoutePaths._();
}
