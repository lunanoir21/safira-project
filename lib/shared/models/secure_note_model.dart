// lib/shared/models/secure_note_model.dart
// Production-quality Isar schema for secure notes.

import 'package:isar/isar.dart';

part 'secure_note_model.g.dart';

@collection
class SecureNoteModel {
  Id id = Isar.autoIncrement;

  @Index(type: IndexType.value)
  late String title;

  /// AES-256-GCM encrypted content.
  /// Format: "&lt;nonce_b64&gt;:&lt;tag_b64&gt;:&lt;ciphertext_b64&gt;"
  late String encryptedContent;

  /// Optional tags for organisation.
  late List<String> tags;

  /// Colour label (hex string, e.g. '#FF5733') — stored in plaintext for UI.
  String? colorLabel;

  @Index(type: IndexType.value)
  late bool isFavorite;

  @Index(type: IndexType.value)
  late bool isDeleted;

  late DateTime createdAt;
  late DateTime updatedAt;
  DateTime? deletedAt;

  SecureNoteModel({
    this.id = Isar.autoIncrement,
    required this.title,
    required this.encryptedContent,
    List<String>? tags,
    this.colorLabel,
    this.isFavorite = false,
    this.isDeleted = false,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  }) : tags = tags ?? [];
}
