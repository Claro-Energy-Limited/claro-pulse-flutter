import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session tokens in the Android Keystore-backed secure storage,
/// ported from the Kotlin `AuthTokenStore`.
///
/// Secure storage is asynchronous, so [load] reads everything once at start-up
/// and values are cached in memory for fast synchronous reads (the auth
/// interceptor needs the current token on every request).
///
/// Every storage call has a timeout. On some devices and emulators the
/// Keystore can be very slow or stop responding; the app must still start and
/// let the user sign in. The worst case is that a session is not remembered
/// after a restart, which only means signing in again.
///
/// Corruption recovery is kept from the Kotlin version: if stored data can no
/// longer be decrypted (a backup/restore without the hardware-bound key, or a
/// Keystore reset), the unreadable data is wiped rather than crashing on every launch.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage, this.timeout = const Duration(seconds: 4)])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Duration timeout;

  static const _kAccessToken = 'access_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kPhone = 'phone';

  String? _accessToken;
  String? _refreshToken;
  String? _phone;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get phone => _phone;
  bool get isSignedIn => _accessToken != null;

  /// Call once at start-up, before reading anything.
  Future<void> load() async {
    try {
      final values = await _storage.readAll().timeout(timeout);
      _accessToken = values[_kAccessToken];
      _refreshToken = values[_kRefreshToken];
      _phone = values[_kPhone];
    } on TimeoutException {
      debugPrint('TokenStore: secure storage did not respond; starting signed out');
      _clearMemory();
    } catch (e) {
      debugPrint('TokenStore: secure storage unreadable, resetting ($e)');
      _clearMemory();
      await _persist('reset', () => _storage.deleteAll());
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String phone,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _phone = phone;
    await _persist('save session', () async {
      await _storage.write(key: _kAccessToken, value: accessToken);
      await _storage.write(key: _kRefreshToken, value: refreshToken);
      await _storage.write(key: _kPhone, value: phone);
    });
  }

  /// Rotates the token pair after a silent refresh. Leaves [phone] untouched:
  /// a refresh proves nothing new about which phone the session belongs to.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _persist('update tokens', () async {
      await _storage.write(key: _kAccessToken, value: accessToken);
      await _storage.write(key: _kRefreshToken, value: refreshToken);
    });
  }

  Future<void> clearSession() async {
    _clearMemory();
    await _persist('clear session', () async {
      await _storage.delete(key: _kAccessToken);
      await _storage.delete(key: _kRefreshToken);
      await _storage.delete(key: _kPhone);
    });
  }

  void _clearMemory() {
    _accessToken = null;
    _refreshToken = null;
    _phone = null;
  }

  /// The in-memory values are already updated; a slow or failing write only
  /// means the change may not survive an app restart.
  Future<void> _persist(String what, Future<void> Function() write) async {
    try {
      await write().timeout(timeout);
    } catch (e) {
      debugPrint('TokenStore: could not $what in secure storage ($e)');
    }
  }
}
