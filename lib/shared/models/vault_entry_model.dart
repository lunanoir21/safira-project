import 'package:isar/isar.dart';

part 'vault_entry_model.g.dart';

/// Isar schema for an encrypted vault entry.
///
/// IMPORTANT: All sensitive fields (password, notes, custom fields) are stored
/// as encrypted bytes. The [encryptedData] field contains the AES-256-GCM
/// encrypted JSON blob with all sensitive data.
///
/// Only metadata needed for display/search (title, category, tags, url)
/// is stored as plaintext — consider encrypting these too in a future version
/// for maximum privacy (at the cost of search performance).
@collection
class VaultEntryModel {
  VaultEntryModel({
    required this.id,
    required this.title,
    required this.encryptedData,
    required this.encryptedDataNonce,
    required this.encryptedDataMac,
    required this.createdAt,
    required this.updatedAt,
    this.username = '',
    this.url = '',
    this.category = '',
    this.isFavorite = false,
    this.isDeleted = false,
    this.deletedAt,
    this.tags = const [],
    this.iconName,
    this.color,
    this.hasTOTP = false,
  });

  Id id;

  /// Display title (not encrypted — needed for search)
  @Index(type: IndexType.value)
  String title;

  /// Username/email (not encrypted — shown in list view)
  String username;

  /// URL/domain (not encrypted — used for favicon)
  String url;

  /// Category name (not encrypted — used for filtering)
  @Index(type: IndexType.value)
  String category;

  /// AES-256-GCM encrypted JSON blob containing:
  /// { password, notes, customFields, totpSecret, ... }
  @Uint8ListConverter()
  List<int> encryptedData;

  /// GCM nonce for [encryptedData]
  @Uint8ListConverter()
  List<int> encryptedDataNonce;

  /// GCM authentication tag for [encryptedData]
  @Uint8ListConverter()
  List<int> encryptedDataMac;

  /// Tags for flexible categorization
  List<String> tags;

  /// Whether this entry is marked as favorite
  bool isFavorite;

  /// Soft-delete flag
  bool isDeleted;

  /// When this entry was soft-deleted
  DateTime? deletedAt;

  /// Whether this entry has a TOTP secret configured
  bool hasTOTP;

  /// Icon identifier (material icon name or custom)
  String? iconName;

  /// Custom accent color (hex string)
  String? color;

  /// Creation timestamp
  DateTime createdAt;

  /// Last modification timestamp
  DateTime updatedAt;
}

/// Isar schema for vault metadata (stored separately, not encrypted).
@collection
class VaultMetadataModel {
  VaultMetadataModel({
    required this.id,
    required this.keySalt,
    required this.verificationHash,
    required this.verificationSalt,
    required this.createdAt,
    required this.schemaVersion,
    this.biometricEnabled = false,
    this.lastUnlockedAt,
  });

  Id id;

  /// Argon2id salt used to derive the encryption key (safe to store)
  @Uint8ListConverter()
  List<int> keySalt;

  /// Argon2id hash used to verify the master password (safe to store)
  @Uint8ListConverter()
  List<int> verificationHash;

  /// Salt used to derive the verification hash (safe to store)
  @Uint8ListConverter()
  List<int> verificationSalt;

  /// Whether biometric unlock is configured
  bool biometricEnabled;

  /// When the vault was created
  DateTime createdAt;

  /// Database schema version for migrations
  int schemaVersion;

  /// Last successful unlock timestamp
  DateTime? lastUnlockedAt;
}

/// Isar schema for app settings.
@collection
class AppSettingsModel {
  AppSettingsModel({
    required this.id,
    this.themeMode = 'system',
    this.themeSeedColor,
    this.sessionTimeoutMinutes = 5,
    this.clipboardClearSeconds = 30,
    this.autoLockOnBackground = true,
    this.showPasswordOnReveal = true,
    this.defaultPasswordLength = 16,
    this.defaultIncludeSymbols = true,
    this.defaultIncludeNumbers = true,
    this.defaultIncludeUppercase = true,
  });

  Id id;
  String themeMode;
  int? themeSeedColor;
  int sessionTimeoutMinutes;
  int clipboardClearSeconds;
  bool autoLockOnBackground;
  bool showPasswordOnReveal;
  int defaultPasswordLength;
  bool defaultIncludeSymbols;
  bool defaultIncludeNumbers;
  bool defaultIncludeUppercase;
}

/// Custom Isar converter for List<int> (byte arrays).
class Uint8ListConverter extends TypeConverter<List<int>, String> {
  const Uint8ListConverter();

  @override
  List<int> fromIsar(String object) =>
      object.isEmpty ? [] : object.split(',').map(int.parse).toList();

  @override
  String toIsar(List<int> object) => object.join(',');
}
