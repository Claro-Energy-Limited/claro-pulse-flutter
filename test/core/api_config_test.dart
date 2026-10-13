import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/config/api_config.dart';

void main() {
  group('deriveRefreshUrl', () {
    test('swaps the /app/v1 suffix for the operator-plane refresh path', () {
      expect(
        deriveRefreshUrl('https://rms.example.com/app/v1/'),
        'https://rms.example.com/api/v1/auth/refresh',
      );
    });

    test('works without a trailing slash', () {
      expect(
        deriveRefreshUrl('http://10.0.2.2:3101/app/v1'),
        'http://10.0.2.2:3101/api/v1/auth/refresh',
      );
    });

    test('falls back to appending when the suffix is missing', () {
      expect(
        deriveRefreshUrl('https://rms.example.com/'),
        'https://rms.example.com/api/v1/auth/refresh',
      );
    });
  });
}
