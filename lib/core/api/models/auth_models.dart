/// Mirrors the RMS farmer-plane `POST /app/v1/auth/otp/verify` 200 response,
/// ported from the Kotlin `OtpVerifyResponse`.
class OtpVerifyResponse {
  const OtpVerifyResponse({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory OtpVerifyResponse.fromJson(Map<String, dynamic> json) => OtpVerifyResponse(
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
}
