import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// The farmer's app preferences. For now: light, dark, or follow the phone.
///
/// Stored with the same secure storage as the session (no extra package), with
/// timeouts: a slow store must never block start-up. If it can't be read, the
/// app simply follows the phone's setting.
class AppSettings {
  AppSettings([FlutterSecureStorage? storage, this.timeout = const Duration(seconds: 3)])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  final Duration timeout;

  static const _kThemeMode = 'theme_mode';

  /// Follows the phone ([ThemeMode.system]) until the farmer chooses otherwise.
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    try {
      final stored = await _storage.read(key: _kThemeMode).timeout(timeout);
      themeMode.value = ThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => ThemeMode.system,
      );
    } catch (e) {
      debugPrint('AppSettings: could not read settings ($e); following the phone');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    try {
      await _storage.write(key: _kThemeMode, value: mode.name).timeout(timeout);
    } catch (e) {
      debugPrint('AppSettings: could not save theme ($e)');
    }
  }
}
