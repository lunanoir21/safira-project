/// Typed exceptions used in the data layer.
/// These are converted to [Failure] objects in repository implementations.

/// Base exception — never throw this directly
abstract class AppException implements Exception {
  const AppException({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => 'AppException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

class CryptoException extends AppException {
  const CryptoException({required super.message, super.cause});
}

class AuthException extends AppException {
  const AuthException({required super.message, super.cause});
}

class DatabaseException extends AppException {
  const DatabaseException({required super.message, super.cause});
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.cause});
}

class ParseException extends AppException {
  const ParseException({required super.message, super.cause});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.cause});
}
