import 'package:flutter/foundation.dart';

/// Base URL of the backend. Every API path is relative to it.
///
/// Set per build with `--dart-define=API_BASE_URL=https://.../app/v1/`. The default
/// targets a backend on your own PC from the Android emulator: inside the
/// emulator, `10.0.2.2` means "the computer running the emulator". It must end
/// in `/app/v1/`, the same base the Kotlin app used.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3101/app/v1/',
);

/// When true, the app uses built-in fake data instead of calling the backend,
/// so every screen can be used and tested without a server.
///
/// On by default in debug builds, always off in release builds unless set.
/// Override with `--dart-define=MOCK_API=false` to use the real backend in debug.
const bool useMockApi = bool.fromEnvironment('MOCK_API', defaultValue: kDebugMode);

/// The token refresh endpoint is `POST /api/v1/auth/refresh`, NOT under
/// `/app/v1/`; there is no separate refresh route under `/app/v1/`. Both share
/// one origin, so the URL is derived from [baseUrl]. A base URL without the
/// expected `/app/v1` suffix falls back to appending the path, best effort: a
/// failed refresh already signs the user out safely.
String deriveRefreshUrl(String baseUrl) {
  final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
  const suffix = '/app/v1';
  if (trimmed.endsWith(suffix)) {
    return '${trimmed.substring(0, trimmed.length - suffix.length)}/api/v1/auth/refresh';
  }
  return '$trimmed/api/v1/auth/refresh';
}
