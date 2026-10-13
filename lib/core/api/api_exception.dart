import 'dart:io' show SocketException;

import 'package:dio/dio.dart';

/// Every API error, with a message already safe to show a farmer, ported from
/// the Kotlin `apiCall` / `ApiException`.
///
/// Every RMS error body, API-wide, is `{ error: { code, message, details, request_id } }`
/// (the server's global exception filter, confirmed against a live server in the
/// Kotlin app). Screens that need to branch on a specific failure, such as
/// `OTP_MAX_ATTEMPTS_EXCEEDED`, read [code]; everything else just shows [message].
class ApiException implements Exception {
  const ApiException({this.code, required this.message});

  final String? code;
  final String message;

  static const genericMessage = 'Something went wrong. Please try again.';
  static const networkMessage =
      "Couldn't reach the server. Check your connection and try again.";

  factory ApiException.fromDio(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return const ApiException(message: networkMessage);
      case DioExceptionType.unknown when e.error is SocketException:
        return const ApiException(message: networkMessage);
      default:
        break;
    }

    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      final code = error['code'];
      final message = error['message'];
      return ApiException(
        code: code is String ? code : null,
        message: message is String && message.isNotEmpty ? message : genericMessage,
      );
    }
    return const ApiException(message: genericMessage);
  }

  @override
  String toString() => message;
}

/// Runs one API call and converts any network or server failure into an [ApiException].
Future<T> apiCall<T>(Future<T> Function() block) async {
  try {
    return await block();
  } on DioException catch (e) {
    throw ApiException.fromDio(e);
  }
}
