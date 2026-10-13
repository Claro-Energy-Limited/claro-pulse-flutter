import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'models/auth_models.dart';
import 'models/device_models.dart';

/// The RMS farmer-plane API, ported from the Kotlin `ClaroPulseApiService`.
///
/// The client's base URL already ends in `/app/v1/`, so every path here is
/// relative to it (no leading slash). Every method throws [ApiException] on failure.
class ClaroPulseApi {
  ClaroPulseApi(this._dio);

  final Dio _dio;

  Future<void> requestOtp(String phone) => apiCall(() async {
        await _dio.post<dynamic>('auth/otp/request', data: {'phone': phone});
      });

  Future<OtpVerifyResponse> verifyOtp(String phone, String code) => apiCall(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          'auth/otp/verify',
          data: {'phone': phone, 'code': code},
        );
        return OtpVerifyResponse.fromJson(res.data!);
      });

  Future<List<MyDevice>> listMyDevices() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('me/devices');
        return (res.data!['items'] as List)
            .map((e) => MyDevice.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  /// [proofReference] is required by the server: it is what the reviewing admin
  /// reads when approving the claim.
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

  Future<DeviceClaimsPage> listMyDeviceClaims() => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('me/device-claims');
        return DeviceClaimsPage.fromJson(res.data!);
      });

  Future<DeviceStatus> getDeviceStatus(String deviceId) => apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>('me/devices/$deviceId/status');
        return DeviceStatus.fromJson(res.data!);
      });

  Future<DeviceActivity> getDeviceActivity(String deviceId, ActivityRange range) =>
      apiCall(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          'me/devices/$deviceId/activity',
          queryParameters: {'range': range.queryValue},
        );
        return DeviceActivity.fromJson(res.data!);
      });
}
