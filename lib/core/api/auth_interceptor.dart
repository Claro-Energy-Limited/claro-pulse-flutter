import 'package:dio/dio.dart';

import '../auth/session_expiry.dart';
import '../auth/token_store.dart';

/// Attaches the Bearer token and silently refreshes an expired session once,
/// ported from the Kotlin `AuthInterceptor` + `TokenRefresher`. Same guards:
///
/// 1. Host-scoped: the token is only sent to this app's own API host, so a
///    redirect to another host (e.g. a signed file URL) never carries it.
/// 2. A 401 only ends the session when a token was actually sent. A wrong OTP on
///    `auth/otp/verify` also returns 401, and must not sign out a session that
///    never existed. The two OTP routes are pre-auth.
/// 3. One silent refresh-and-retry, never a loop.
/// 4. Concurrent 401s share ONE refresh. The server rotates and revokes a refresh
///    token on first use, so a second request presenting the same one would be
///    told the session was revoked. [QueuedInterceptor] runs error handlers one
///    at a time; the second handler sees the token already changed and reuses it.
///
/// Retries and the refresh call go through [plainDio] (no interceptors). Retrying
/// through the main client from inside a [QueuedInterceptor] can deadlock, and
/// refreshing through it would recurse back into this interceptor.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.tokenStore,
    required this.sessionExpiry,
    required this.plainDio,
    required this.apiBaseUrl,
    required this.refreshUrl,
  });

  final TokenStore tokenStore;
  final SessionExpiry sessionExpiry;
  final Dio plainDio;
  final String apiBaseUrl;
  final String refreshUrl;

  static const _sentTokenKey = 'claro.sentToken';
  static const _preAuthPaths = ['auth/otp/request', 'auth/otp/verify'];

  late final String? _apiHost = Uri.tryParse(apiBaseUrl)?.host;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = tokenStore.accessToken;
    if (token != null && (_apiHost == null || options.uri.host == _apiHost)) {
      options.headers['Authorization'] = 'Bearer $token';
      options.extra[_sentTokenKey] = token;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final options = err.requestOptions;
    final sentToken = options.extra[_sentTokenKey] as String?;
    final isPreAuth = _preAuthPaths.any(options.uri.path.endsWith);

    if (err.response?.statusCode != 401 || sentToken == null || isPreAuth) {
      return handler.next(err);
    }

    final newToken = await _refresh(rejectedToken: sentToken);
    if (newToken == null) {
      await tokenStore.clearSession();
      sessionExpiry.signalExpired();
      return handler.next(err);
    }

    try {
      options.headers['Authorization'] = 'Bearer $newToken';
      options.extra[_sentTokenKey] = newToken;
      final response = await plainDio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (retryError) {
      return handler.next(retryError);
    }
  }

  /// Returns a usable access token, or null if the session cannot be renewed.
  Future<String?> _refresh({required String rejectedToken}) async {
    // Another request already refreshed while this one waited its turn.
    final current = tokenStore.accessToken;
    if (current != null && current != rejectedToken) return current;

    final refreshToken = tokenStore.refreshToken;
    if (refreshToken == null) return null;

    try {
      final response = await plainDio.post<Map<String, dynamic>>(
        refreshUrl,
        data: {'refreshToken': refreshToken},
      );
      final access = response.data?['accessToken'];
      final refresh = response.data?['refreshToken'];
      if (access is String && access.isNotEmpty && refresh is String && refresh.isNotEmpty) {
        await tokenStore.updateTokens(accessToken: access, refreshToken: refresh);
        return access;
      }
      return null;
    } on DioException {
      return null;
    }
  }
}
