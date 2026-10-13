import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api/auth_interceptor.dart';
import 'api/claro_pulse_api.dart';
import 'api/mock_claro_pulse_api.dart';
import 'auth/session_expiry.dart';
import 'auth/token_store.dart';
import 'config/api_config.dart';

/// The app's shared services, ported from the Kotlin `ServiceLocator`.
///
/// Kept as a plain object, like the Kotlin app. If the team later picks
/// Riverpod or Bloc, these become providers; screens need little change.
class AppServices {
  AppServices({
    required this.tokenStore,
    required this.sessionExpiry,
    required this.api,
    required this.isMock,
  });

  final TokenStore tokenStore;
  final SessionExpiry sessionExpiry;
  final ClaroPulseApi api;

  /// True when [api] is the built-in fake backend (see [useMockApi]).
  final bool isMock;

  /// Builds everything once at start-up. Never blocks for long: storage reads
  /// have a timeout (see [TokenStore]).
  static Future<AppServices> create() async {
    final tokenStore = TokenStore();
    await tokenStore.load();
    final sessionExpiry = SessionExpiry();

    if (useMockApi) {
      debugPrint('ClaroPulse: MOCK API in use (sign in with code ${MockClaroPulseApi.otpCode})');
      return AppServices(
        tokenStore: tokenStore,
        sessionExpiry: sessionExpiry,
        api: MockClaroPulseApi(),
        isMock: true,
      );
    }

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

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true, logPrint: (o) => debugPrint('$o')),
      );
    }

    return AppServices(
      tokenStore: tokenStore,
      sessionExpiry: sessionExpiry,
      api: HttpClaroPulseApi(dio),
      isMock: false,
    );
  }
}
