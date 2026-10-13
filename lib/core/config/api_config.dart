/// Base URL of the RMS farmer plane. Every API path is relative to it.
///
/// Set per build with `--dart-define=API_BASE_URL=https://.../app/v1/`. The default
/// targets the RMS API on your own PC from the Android emulator: inside the
/// emulator, `10.0.2.2` means "the computer running the emulator", and RMS's API
/// runs on port 3101 locally. It must end in `/app/v1/`.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:3101/app/v1/',
);

/// The token refresh endpoint is `POST /api/v1/auth/refresh`, on the operator
/// plane, NOT under `/app/v1/`. There is no separate farmer-plane refresh route.
/// Both planes share one origin, so the URL is derived from [baseUrl].
/// A base URL without the expected `/app/v1` suffix falls back to appending
/// the path, best effort: a failed refresh already signs the user out safely.
String deriveRefreshUrl(String baseUrl) {
  final trimmed = baseUrl.replaceAll(RegExp(r'/+$'), '');
  const suffix = '/app/v1';
  if (trimmed.endsWith(suffix)) {
    return '${trimmed.substring(0, trimmed.length - suffix.length)}/api/v1/auth/refresh';
  }
  return '$trimmed/api/v1/auth/refresh';
}
