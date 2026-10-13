import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/api/api_exception.dart';

DioException _badResponse(Object? body, {int status = 400}) {
  final options = RequestOptions(path: 'auth/otp/verify');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<Object?>(requestOptions: options, statusCode: status, data: body),
  );
}

void main() {
  test('reads code and message from the RMS error envelope', () {
    final e = ApiException.fromDio(_badResponse({
      'error': {
        'code': 'OTP_INVALID',
        'message': 'The code is invalid or has expired',
        'request_id': 'abc',
      },
    }));
    expect(e.code, 'OTP_INVALID');
    expect(e.message, 'The code is invalid or has expired');
  });

  test('falls back to the generic message for an unexpected body', () {
    final e = ApiException.fromDio(_badResponse({'code': 'X', 'message': 'flat shape'}));
    expect(e.code, isNull);
    expect(e.message, ApiException.genericMessage);
  });

  test('network failures get the connection message, not a raw error', () {
    final e = ApiException.fromDio(DioException(
      requestOptions: RequestOptions(path: 'me/devices'),
      type: DioExceptionType.connectionError,
    ));
    expect(e.message, ApiException.networkMessage);
  });
}
