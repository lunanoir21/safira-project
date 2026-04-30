import 'package:equatable/equatable.dart';

/// Base failure class — all domain-level errors extend this.
/// Uses the Either pattern (dartz) for functional error handling.
abstract class Failure extends Equatable {
  const Failure({
    required this.message,
    this.code,
    this.stackTrace,
  });

  final String message;
  final String? code;
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [message, code];

  @override
  String toString() => 'Failure(code: $code, message: $message)';
}

// ─── Crypto Failures ─────────────────────────────────────────────────────────

/// Thrown when encryption or decryption fails
class EncryptionFailure extends Failure {
  const EncryptionFailure({
    super.message = 'Encryption failed',
    super.code = 'ENCRYPTION_ERROR',
    super.stackTrace,
  });
}

/// Thrown when decryption fails (wrong key / corrupted data)
class DecryptionFailure extends Failure {
  const DecryptionFailure({
    super.message = 'Decryption failed — wrong password or corrupted data',
    super.code = 'DECRYPTION_ERROR',
    super.stackTrace,
  });
}

/// Thrown when key derivation fails
class KeyDerivationFailure extends Failure {
  const KeyDerivationFailure({
    super.message = 'Key derivation failed',
    super.code = 'KDF_ERROR',
    super.stackTrace,
  });
}

// ─── Auth Failures ────────────────────────────────────────────────────────────

/// Thrown when master password is incorrect
class WrongPasswordFailure extends Failure {
  const WrongPasswordFailure({
    required this.remainingAttempts,
    super.message = 'Incorrect master password',
    super.code = 'WRONG_PASSWORD',
    super.stackTrace,
  });

  final int remainingAttempts;

  @override
  List<Object?> get props => [...super.props, remainingAttempts];
}

/// Thrown when account is locked due to too many failed attempts
class AccountLockedFailure extends Failure {
  const AccountLockedFailure({
    required this.lockDurationSeconds,
    super.message = 'Account locked due to too many failed attempts',
    super.code = 'ACCOUNT_LOCKED',
    super.stackTrace,
  });

  final int lockDurationSeconds;

  @override
  List<Object?> get props => [...super.props, lockDurationSeconds];
}

/// Thrown when biometric auth fails or is unavailable
class BiometricFailure extends Failure {
  const BiometricFailure({
    super.message = 'Biometric authentication failed',
    super.code = 'BIOMETRIC_ERROR',
    super.stackTrace,
  });
}

/// Thrown when session has expired
class SessionExpiredFailure extends Failure {
  const SessionExpiredFailure({
    super.message = 'Session expired — please unlock again',
    super.code = 'SESSION_EXPIRED',
    super.stackTrace,
  });
}

// ─── Vault Failures ───────────────────────────────────────────────────────────

/// Thrown when a vault entry is not found
class EntryNotFoundFailure extends Failure {
  const EntryNotFoundFailure({
    required this.entryId,
    super.message = 'Vault entry not found',
    super.code = 'ENTRY_NOT_FOUND',
    super.stackTrace,
  });

  final String entryId;

  @override
  List<Object?> get props => [...super.props, entryId];
}

/// Thrown when vault read/write fails
class VaultStorageFailure extends Failure {
  const VaultStorageFailure({
    super.message = 'Vault storage operation failed',
    super.code = 'VAULT_STORAGE_ERROR',
    super.stackTrace,
  });
}

/// Thrown when vault is corrupted
class VaultCorruptedFailure extends Failure {
  const VaultCorruptedFailure({
    super.message = 'Vault data appears to be corrupted',
    super.code = 'VAULT_CORRUPTED',
    super.stackTrace,
  });
}

// ─── Network Failures ─────────────────────────────────────────────────────────

/// Thrown when a network request fails
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'Network request failed',
    super.code = 'NETWORK_ERROR',
    super.stackTrace,
  });
}

/// Thrown when HaveIBeenPwned API fails
class BreachCheckFailure extends Failure {
  const BreachCheckFailure({
    super.message = 'Could not check breach status',
    super.code = 'BREACH_CHECK_ERROR',
    super.stackTrace,
  });
}

// ─── Import/Export Failures ───────────────────────────────────────────────────

/// Thrown when import parsing fails
class ImportParseFailure extends Failure {
  const ImportParseFailure({
    super.message = 'Failed to parse import file',
    super.code = 'IMPORT_PARSE_ERROR',
    super.stackTrace,
  });
}

/// Thrown when export fails
class ExportFailure extends Failure {
  const ExportFailure({
    super.message = 'Failed to export vault data',
    super.code = 'EXPORT_ERROR',
    super.stackTrace,
  });
}

// ─── Validation Failures ──────────────────────────────────────────────────────

/// Thrown when input validation fails
class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.stackTrace,
  });
}

// ─── Generic Failures ─────────────────────────────────────────────────────────

/// Catch-all for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'An unexpected error occurred',
    super.code = 'UNEXPECTED_ERROR',
    super.stackTrace,
  });
}

/// Thrown when a feature is not yet implemented on the current platform
class UnsupportedPlatformFailure extends Failure {
  const UnsupportedPlatformFailure({
    required String feature,
    super.code = 'UNSUPPORTED_PLATFORM',
    super.stackTrace,
  }) : super(message: '$feature is not supported on this platform');
}
