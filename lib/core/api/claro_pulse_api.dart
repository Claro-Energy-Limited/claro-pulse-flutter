import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'models/auth_models.dart';
import 'models/device_models.dart';

/// Everything the app asks the backend, ported from the Kotlin
/// `ClaroPulseApiService`. Two implementations: [HttpClaroPulseApi] talks to the
/// real server; `MockClaroPulseApi` returns built-in fake data. Screens only
/// see this interface, so switching between them changes nothing on screen.
///
/// Every method throws [ApiException] on failure.
abstract interface class ClaroPulseApi {
  Future<void> requestOtp(String phone);

  Future<OtpVerifyResponse> verifyOtp(String phone, String code);

  Future<List<MyDevice>> listMyDevices();

  /// [proofReference] is required by the server: it is what the reviewing admin
  /// reads when approving the claim.
  Future<DeviceClaim> submitDeviceClaim({
    required String deviceIdentifier,
    required String proofReference,
  });

  Future<DeviceClaimsPage> listMyDeviceClaims();

  Future<DeviceStatus> getDeviceStatus(String deviceId);

  Future<DeviceActivity> getDeviceActivity(String deviceId, ActivityRange range);
}

/// The real backend. The client's base URL already ends in `/app/v1/`, so every
/// path here is relative to it (no leading slash).
class HttpClaroPulseApi implements ClaroPulseApi {
  HttpClaroPulseApi(this._dio);

  final Dio _dio;

  @override
  Future<void> requestOtp(String phone) => apiCall(() async {
        await _dio.post<dynamic>('auth/otp/request', data: {'phone': phone});
      });

  @override
  Future<OtpVerifyResponse> verifyOtp(String phone, String code) => apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          'auth/otp/verify',
          data: {'phone': phone, 'code': code},
        );
        return OtpVerifyResponse.fromJson(res.data!);
      });

  @override
  Future<List<MyDevice>> listMyDevices() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('me/devices');
        return (res.data!['items'] as List)
            .map((e) => MyDevice.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<DeviceClaim> submitDeviceClaim({
    required String deviceIdentifier,
    required String proofReference,
  }) =>
      apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          'me/device-claims',
          data: {'deviceIdentifier': deviceIdentifier, 'proofReference': proofReference},
        );
        return DeviceClaim.fromJson(res.data!['claim'] as Map<String, dynamic>);
      });

  @override
  Future<DeviceClaimsPage> listMyDeviceClaims() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('me/device-claims');
        return DeviceClaimsPage.fromJson(res.data!);
      });

  @override
  Future<DeviceStatus> getDeviceStatus(String deviceId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('me/devices/$deviceId/status');
        return DeviceStatus.fromJson(res.data!);
      });

  @override
  Future<DeviceActivity> getDeviceActivity(String deviceId, ActivityRange range) =>
      apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          'me/devices/$deviceId/activity',
          queryParameters: {'range': range.queryValue},
        );
        return DeviceActivity.fromJson(res.data!);
      });
}
