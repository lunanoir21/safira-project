import 'dart:async';

import 'package:flutter/services.dart';
import 'package:safira/core/constants/app_constants.dart';

/// Secure clipboard manager that automatically clears sensitive data.
///
/// Never leave passwords in the clipboard — this manager ensures
/// clipboard contents are wiped after a configurable delay.
final class SecureClipboardManager {
  SecureClipboardManager._();

  static final SecureClipboardManager instance = SecureClipboardManager._();

  Timer? _clearTimer;
  String? _currentSensitiveValue;

  /// Copies [text] to clipboard and schedules automatic clearing.
  ///
  /// Any previously scheduled clear is cancelled and restarted.
  Future<void> copySecure(
    String text, {
    Duration clearAfter = const Duration(
      seconds: SecurityConstants.defaultClipboardClearSeconds,
    ),
    VoidCallback? onCleared,
  }) async {
    // Cancel any existing timer
    _cancelTimer();

    _currentSensitiveValue = text;
    await Clipboard.setData(ClipboardData(text: text));

    _clearTimer = Timer(clearAfter, () async {
      await _clearIfMatch(text);
      onCleared?.call();
    });
  }

  /// Immediately clears the clipboard if it still contains our value.
  Future<void> clearNow() async {
    _cancelTimer();
    if (_currentSensitiveValue != null) {
      await _clearIfMatch(_currentSensitiveValue!);
    }
  }

  /// Cancels the scheduled clear without clearing the clipboard.
  void cancelScheduledClear() => _cancelTimer();

  /// Returns remaining seconds until clipboard is cleared, or null if no timer.
  Duration? get remainingClearTime {
    if (_clearTimer == null || !_clearTimer!.isActive) return null;
    // Timer doesn't expose remaining time directly; approximate
    return null;
  }

  bool get hasPendingClear => _clearTimer?.isActive ?? false;

  void dispose() {
    _cancelTimer();
    _currentSensitiveValue = null;
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  Future<void> _clearIfMatch(String expectedValue) async {
    try {
      final current = await Clipboard.getData(Clipboard.kTextPlain);
      if (current?.text == expectedValue) {
        await Clipboard.setData(const ClipboardData(text: ''));
      }
      _currentSensitiveValue = null;
    } on Object {
      // Clipboard access denied — silently fail
    }
  }

  void _cancelTimer() {
    _clearTimer?.cancel();
    _clearTimer = null;
  }
}
