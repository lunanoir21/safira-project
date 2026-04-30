// lib/shared/models/vault_entry_model.dart
// Production Isar schemas — base64 byte storage, unified clean fields.

import 'dart:convert';
import 'dart:typed_data';
import 'package:isar/isar.dart';

part 'vault_entry_model.g.dart';

// ─── Byte-array converter (base64 — replaces inefficient comma-join) ──────────

class Uint8ListConverter extends TypeConverter<Uint8List, String> {
  const Uint8ListConverter();

  @override
  Uint8List fromIsar(String object) =>
      object.isEmpty ? Uint8List(0) : base64.decode(object);

  @override
  String toIsar(Uint8List object) => base64.encode(object);
}

// ─── VaultEntryModel ─────────────────────────────────────────────────────────

/// One encrypted credential entry in the vault.
///
/// **Privacy design:**
/// - `title`, `username`, `url`, `category` stored as plaintext for search/display.
/// - All sensitive data (password, notes, TOTP secret, custom fields) lives in
///   [encryptedData] as AES-256-GCM ciphertext of a JSON blob.
@collection
class VaultEntryModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  late String username;

  @Index(type: IndexType.value)
  late String url;

  @Index(type: IndexType.value)
  late String category;

  /// AES-256-GCM encrypted JSON blob (Uint8List → base64 in Isar).
  @Uint8ListConverter()
  late Uint8List encryptedData;

  /// GCM nonce (12 bytes).
  @Uint8ListConverter()
  late Uint8List encryptedDataNonce;

  /// GCM authentication tag (16 bytes).
  @Uint8ListConverter()
  late Uint8List encryptedDataMac;

  late List<String> tags;

  @Index(type: IndexType.value)
  late bool isFavorite;

  @Index(type: IndexType.value)
  late bool isDeleted;

  DateTime? deletedAt;

  late bool hasTOTP;

  String? iconName;

  String? colorHex;

  late DateTime createdAt;
  late DateTime updatedAt;

  VaultEntryModel({
    this.id = Isar.autoIncrement,
    required this.title,
    this.username = '',
    this.url = '',
    this.category = 'Login',
    required this.encryptedData,
    required this.encryptedDataNonce,
    required this.encryptedDataMac,
    List<String>? tags,
    this.isFavorite = false,
    this.isDeleted = false,
    this.deletedAt,
    this.hasTOTP = false,
    this.iconName,
    this.colorHex,
    required this.createdAt,
    required this.updatedAt,
  }) : tags = tags ?? [];
}

// ─── VaultSensitiveData ──────────────────────────────────────────────────────

/// The decrypted sensitive payload stored inside [VaultEntryModel.encryptedData].
/// Serialised as JSON before encryption.
class VaultSensitiveData {
  final String password;
  final String notes;
  final String? totpSecret;
  final List<CustomField> customFields;

  const VaultSensitiveData({
    required this.password,
    this.notes = '',
    this.totpSecret,
    this.customFields = const [],
  });

  factory VaultSensitiveData.fromJson(Map<String, dynamic> json) =>
      VaultSensitiveData(
        password: (json['password'] as String?) ?? '',
        notes: (json['notes'] as String?) ?? '',
        totpSecret: json['totpSecret'] as String?,
        customFields: (json['customFields'] as List<dynamic>?)
                ?.map((e) => CustomField.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'password': password,
        'notes': notes,
        if (totpSecret != null) 'totpSecret': totpSecret,
        'customFields': customFields.map((f) => f.toJson()).toList(),
      };

  Uint8List toBytes() =>
      Uint8List.fromList(utf8.encode(jsonEncode(toJson())));

  static VaultSensitiveData fromBytes(Uint8List bytes) =>
      VaultSensitiveData.fromJson(
        jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
      );
}

class CustomField {
  final String label;
  final String value;
  final bool isHidden;

  const CustomField({
    required this.label,
    required this.value,
    this.isHidden = false,
  });

  factory CustomField.fromJson(Map<String, dynamic> json) => CustomField(
        label: (json['label'] as String?) ?? '',
        value: (json['value'] as String?) ?? '',
        isHidden: (json['isHidden'] as bool?) ?? false,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'value': value,
        'isHidden': isHidden,
      };
}

// ─── VaultMetadataModel ───────────────────────────────────────────────────────

/// Vault-level metadata — stored once per vault, never encrypted.
/// Contains Argon2id parameters needed to re-derive the key on unlock.
@collection
class VaultMetadataModel {
  Id id = Isar.autoIncrement;

  /// Argon2id salt (Uint8List → base64 in Isar).
  @Uint8ListConverter()
  late Uint8List argon2Salt;

  late int argon2MemoryKiB;
  late int argon2Iterations;
  late int argon2Parallelism;

  /// AES-256-GCM encrypted sentinel value for password verification.
  /// Format: "&lt;nonce_b64&gt;:&lt;tag_b64&gt;:&lt;ciphertext_b64&gt;"
  late String encryptedSentinel;

  late DateTime createdAt;
  late DateTime updatedAt;

  VaultMetadataModel({
    this.id = Isar.autoIncrement,
    required this.argon2Salt,
    required this.argon2MemoryKiB,
    required this.argon2Iterations,
    required this.argon2Parallelism,
    required this.encryptedSentinel,
    required this.createdAt,
    required this.updatedAt,
  });
}

// ─── AppSettingsModel ─────────────────────────────────────────────────────────

/// User-configurable app settings — one row in Isar.
@collection
class AppSettingsModel {
  Id id = Isar.autoIncrement;

  /// 'light' | 'dark' | 'system' | 'custom'
  String themeName = 'system';

  /// Custom seed color (hex string, e.g. '#6750A4').
  String? customSeedColor;

  int autoLockMinutes = 15;
  int clipboardClearSeconds = 30;
  bool biometricEnabled = false;
  bool autoLockOnBackground = true;
  bool showPasswordStrengthMeter = true;

  int defaultPasswordLength = 16;
  bool defaultIncludeUppercase = true;
  bool defaultIncludeLowercase = true;
  bool defaultIncludeNumbers = true;
  bool defaultIncludeSymbols = true;

  late DateTime createdAt;
  late DateTime updatedAt;

  AppSettingsModel({
    this.id = Isar.autoIncrement,
    this.themeName = 'system',
    this.customSeedColor,
    this.autoLockMinutes = 15,
    this.clipboardClearSeconds = 30,
    this.biometricEnabled = false,
    this.autoLockOnBackground = true,
    this.showPasswordStrengthMeter = true,
    this.defaultPasswordLength = 16,
    this.defaultIncludeUppercase = true,
    this.defaultIncludeLowercase = true,
    this.defaultIncludeNumbers = true,
    this.defaultIncludeSymbols = true,
    required this.createdAt,
  }) : updatedAt = createdAt;
}
