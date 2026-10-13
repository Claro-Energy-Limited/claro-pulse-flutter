import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Keeps the session tokens in the Android Keystore-backed secure storage,
/// ported from the Kotlin `AuthTokenStore`.
///
/// Secure storage is asynchronous, so [load] reads everything once at start-up
/// and the values are cached in memory for fast synchronous reads (the auth
/// interceptor needs the current token on every request).
///
/// Corruption recovery is kept from the Kotlin version: the Keystore key can end
/// up unable to decrypt stored data (a backup/restore that copied the data but
/// not the hardware-bound key, or a Keystore reset on some devices). Reading
/// then throws on every launch. Recovery is to wipe the unreadable data; losing a
/// cached session just means signing in again, far better than a crash loop.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

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
      _accessToken = await _storage.read(key: _kAccessToken);
      _refreshToken = await _storage.read(key: _kRefreshToken);
      _phone = await _storage.read(key: _kPhone);
    } catch (e) {
      debugPrint('TokenStore: secure storage unreadable, resetting ($e)');
      _accessToken = null;
      _refreshToken = null;
      _phone = null;
      try {
        await _storage.deleteAll();
      } catch (_) {
        // Nothing more to do; the next successful write starts fresh.
      }
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
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
    await _storage.write(key: _kPhone, value: phone);
  }

  /// Rotates the token pair after a silent refresh. Leaves [phone] untouched:
  /// a refresh proves nothing new about which phone the session belongs to.
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.write(key: _kAccessToken, value: accessToken);
    await _storage.write(key: _kRefreshToken, value: refreshToken);
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    _phone = null;
    await _storage.delete(key: _kAccessToken);
    await _storage.delete(key: _kRefreshToken);
    await _storage.delete(key: _kPhone);
  }
}
