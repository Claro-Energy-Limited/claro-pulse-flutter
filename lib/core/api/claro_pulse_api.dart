import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'models/auth_models.dart';
import 'models/device_models.dart';
import 'models/pump_models.dart';

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

  // ── Not on the server yet: only the mock implements these for now. ──────────

  Future<PumpDetails> getPumpDetails(String deviceId);

  Future<List<Complaint>> listComplaints();

  Future<Complaint> createComplaint({
    required String deviceId,
    required ComplaintCategory category,
    required String description,
  });

  Future<List<AppNotification>> listNotifications();

  /// The pump's most recent runs, newest first. If the pump is running now,
  /// the first item is the ongoing run (no end time, totals so far).
  Future<List<PumpRun>> listRecentRuns(String deviceId, {int limit = 5});

  /// Weather, expected water, savings and panel care for the Home screen.
  Future<PumpInsights> getInsights(String deviceId);

  /// This month's summary so far.
  Future<MonthlyReport> getMonthlyReport(String deviceId);

  /// Asks the pump to start or stop. Completing only means the request was
  /// accepted; the pump is running only once its own status says RUNNING.
  Future<void> sendPumpCommand(String deviceId, PumpCommand command);
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

  // The server has no endpoints for these yet. Screens show this message
  // instead of failing silently.
  static const _notAvailable =
      ApiException(code: 'NOT_AVAILABLE', message: "This feature isn't available yet.");

  @override
  Future<PumpDetails> getPumpDetails(String deviceId) async => throw _notAvailable;

  @override
  Future<List<Complaint>> listComplaints() async => throw _notAvailable;

  @override
  Future<Complaint> createComplaint({
    required String deviceId,
    required ComplaintCategory category,
    required String description,
  }) async =>
      throw _notAvailable;

  @override
  Future<List<AppNotification>> listNotifications() async => throw _notAvailable;

  @override
  Future<void> sendPumpCommand(String deviceId, PumpCommand command) async => throw _notAvailable;

  @override
  Future<List<PumpRun>> listRecentRuns(String deviceId, {int limit = 5}) async => throw _notAvailable;

  @override
  Future<PumpInsights> getInsights(String deviceId) async => throw _notAvailable;

  @override
  Future<MonthlyReport> getMonthlyReport(String deviceId) async => throw _notAvailable;
}
