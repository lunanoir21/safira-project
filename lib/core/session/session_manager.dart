import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:safira/core/constants/app_constants.dart';
import 'package:safira/core/security/crypto_engine.dart';

/// Manages the active session and auto-lock behavior.
///
/// The session holds the in-memory encryption key. When the session
/// expires or the app locks, the key is zeroed from memory — making
/// all vault data inaccessible until the user re-authenticates.
final class SessionManager extends ChangeNotifier {
  SessionManager({
    int timeoutMinutes = SecurityConstants.defaultSessionTimeoutMinutes,
  }) : _timeoutDuration = Duration(minutes: timeoutMinutes);

  Duration _timeoutDuration;
  Uint8List? _encryptionKey;
  Timer? _lockTimer;
  DateTime? _lastActivity;
  bool _isLocked = true;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Whether the vault is currently locked.
  bool get isLocked => _isLocked;

  /// Whether a valid session exists (unlocked).
  bool get isUnlocked => !_isLocked && _encryptionKey != null;

  /// The active encryption key — only accessible when session is valid.
  /// Returns null if locked.
  Uint8List? get encryptionKey => isUnlocked ? _encryptionKey : null;

  /// Time since last user activity.
  Duration? get idleTime =>
      _lastActivity != null ? DateTime.now().difference(_lastActivity!) : null;

  /// Session timeout duration.
  Duration get timeoutDuration => _timeoutDuration;

  /// Unlocks the session with the derived encryption key.
  void unlock(Uint8List encryptionKey) {
    _encryptionKey = encryptionKey;
    _isLocked = false;
    _lastActivity = DateTime.now();
    _resetLockTimer();
    notifyListeners();
  }

  /// Locks the session immediately, zeroing the key from memory.
  void lock() {
    _clearKey();
    _isLocked = true;
    _cancelTimer();
    notifyListeners();
  }

  /// Registers user activity — resets the idle timer.
  void recordActivity() {
    if (!isUnlocked) return;
    _lastActivity = DateTime.now();
    _resetLockTimer();
  }

  /// Updates the session timeout duration.
  void updateTimeout(Duration timeout) {
    _timeoutDuration = timeout;
    if (isUnlocked) _resetLockTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _clearKey();
    _cancelTimer();
    super.dispose();
  }

  // ─── Private ──────────────────────────────────────────────────────────────

  void _resetLockTimer() {
    _cancelTimer();
    _lockTimer = Timer(_timeoutDuration, _onTimeout);
  }

  void _onTimeout() {
    lock();
  }

  void _cancelTimer() {
    _lockTimer?.cancel();
    _lockTimer = null;
  }

  void _clearKey() {
    if (_encryptionKey != null) {
      CryptoEngine.zeroMemory(_encryptionKey!);
      _encryptionKey = null;
    }
  }
}
