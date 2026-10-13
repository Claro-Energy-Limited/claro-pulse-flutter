import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api/auth_interceptor.dart';
import 'api/claro_pulse_api.dart';
import 'auth/session_expiry.dart';
import 'auth/token_store.dart';
import 'config/api_config.dart';

/// Builds the app's shared services once, ported from the Kotlin `ServiceLocator`.
///
/// Kept as a plain object for now, like the Kotlin app. If the team picks Riverpod
/// or Bloc, these become providers; nothing else in `core/` needs to change.
class AppServices {
  AppServices._({
    required this.tokenStore,
    required this.sessionExpiry,
    required this.api,
  });

  final TokenStore tokenStore;
  final SessionExpiry sessionExpiry;
  final ClaroPulseApi api;

  /// Call once in `main()` before `runApp`.
  static Future<AppServices> create() async {
    final tokenStore = TokenStore();
    await tokenStore.load();
    final sessionExpiry = SessionExpiry();

    // Rural, poor connectivity is normal for this app: a modest bump over the
    // defaults, not a long wait for a call that was never going to succeed.
    BaseOptions options() => BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 20),
          contentType: Headers.jsonContentType,
        );

    // No interceptors: used only for token refresh and the one retry after it.
    final plainDio = Dio(options());

    final dio = Dio(options())
      ..interceptors.add(
        AuthInterceptor(
          tokenStore: tokenStore,
          sessionExpiry: sessionExpiry,
          plainDio: plainDio,
          apiBaseUrl: apiBaseUrl,
          refreshUrl: deriveRefreshUrl(apiBaseUrl),
        ),
      );

    // Request/response logging in debug builds only, like the Kotlin app.
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, logPrint: (o) => debugPrint('$o')),
      );
    }

    return AppServices._(
      tokenStore: tokenStore,
      sessionExpiry: sessionExpiry,
      api: ClaroPulseApi(dio),
    );
  }
}
