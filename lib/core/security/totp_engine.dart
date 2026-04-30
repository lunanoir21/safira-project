import 'dart:typed_data';

import 'package:base32/base32.dart';
import 'package:otp/otp.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/errors/exceptions.dart';

/// RFC 6238 compliant TOTP (Time-based One-Time Password) engine.
///
/// Compatible with Google Authenticator, Authy, and all RFC 6238 apps.
final class TotpEngine {
  TotpEngine._();

  static final TotpEngine instance = TotpEngine._();

  /// Generates the current TOTP code for [secret].
  ///
  /// [secret] must be a Base32-encoded string (as provided by most services).
  String generateCode(String secret) {
    try {
      final cleanSecret = _cleanSecret(secret);
      return OTP.generateTOTPCodeString(
        cleanSecret,
        DateTime.now().millisecondsSinceEpoch,
        length: CryptoConstants.totpDigits,
        interval: CryptoConstants.totpTimeStep,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
    } on Object catch (e) {
      throw CryptoException(message: 'TOTP generation failed', cause: e);
    }
  }

  /// Verifies [code] against [secret] with a ±1 window tolerance.
  ///
  /// The window allows for clock skew between client and server.
  bool verifyCode(String secret, String code) {
    try {
      final cleanSecret = _cleanSecret(secret);
      final now = DateTime.now().millisecondsSinceEpoch;

      // Check current, previous, and next time windows
      for (final offset in [-1, 0, 1]) {
        final time = now + (offset * CryptoConstants.totpTimeStep * 1000);
        final expected = OTP.generateTOTPCodeString(
          cleanSecret,
          time,
          length: CryptoConstants.totpDigits,
          interval: CryptoConstants.totpTimeStep,
          algorithm: Algorithm.SHA1,
          isGoogle: true,
        );
        if (expected == code) return true;
      }
      return false;
    } on Object {
      return false;
    }
  }

  /// Returns the remaining seconds in the current TOTP window.
  int get remainingSeconds {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return CryptoConstants.totpTimeStep - (epoch % CryptoConstants.totpTimeStep);
  }

  /// Returns a value from 0.0 to 1.0 representing the current window progress.
  double get windowProgress {
    final epoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return (epoch % CryptoConstants.totpTimeStep) / CryptoConstants.totpTimeStep;
  }

  /// Generates a random Base32 TOTP secret (for new entries).
  String generateSecret() {
    final bytes = Uint8List(20); // 160 bits — standard TOTP secret size
    for (var i = 0; i < bytes.length; i++) {
      bytes[i] = DateTime.now().microsecondsSinceEpoch & 0xFF ^ i;
    }
    return base32.encode(bytes);
  }

  /// Parses a TOTP URI (otpauth://totp/...) and returns the secret.
  ///
  /// Returns null if the URI is invalid.
  TotpUriData? parseOtpAuthUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.scheme != 'otpauth' || parsed.host != 'totp') return null;

      final secret = parsed.queryParameters['secret'];
      if (secret == null || secret.isEmpty) return null;

      final issuer = parsed.queryParameters['issuer'];
      final accountName = Uri.decodeComponent(
        parsed.pathSegments.isNotEmpty ? parsed.pathSegments.last : '',
      );

      return TotpUriData(
        secret: secret.toUpperCase(),
        issuer: issuer ?? '',
        accountName: accountName,
      );
    } on Object {
      return null;
    }
  }

  /// Builds an otpauth:// URI for the given secret.
  String buildOtpAuthUri({
    required String secret,
    required String accountName,
    String issuer = 'Safira',
  }) =>
      'otpauth://totp/${Uri.encodeComponent(issuer)}:${Uri.encodeComponent(accountName)}'
      '?secret=$secret&issuer=${Uri.encodeComponent(issuer)}'
      '&algorithm=SHA1&digits=${CryptoConstants.totpDigits}&period=${CryptoConstants.totpTimeStep}';

  // ─── Private ──────────────────────────────────────────────────────────────

  String _cleanSecret(String secret) =>
      secret.toUpperCase().replaceAll(RegExp(r'\s+'), '').replaceAll('=', '');
}

/// Parsed data from an otpauth:// URI.
final class TotpUriData {
  const TotpUriData({
    required this.secret,
    required this.issuer,
    required this.accountName,
  });

  final String secret;
  final String issuer;
  final String accountName;
}
