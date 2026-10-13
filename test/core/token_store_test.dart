import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:claropulse/core/auth/token_store.dart';

void main() {
  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('saves, reloads and clears a session', () async {
    final store = TokenStore();
    await store.load();
    expect(store.isSignedIn, isFalse);

    await store.saveSession(accessToken: 'a1', refreshToken: 'r1', phone: '9876543210');
    final reloaded = TokenStore();
    await reloaded.load();
    expect(reloaded.accessToken, 'a1');
    expect(reloaded.phone, '9876543210');

    await reloaded.updateTokens(accessToken: 'a2', refreshToken: 'r2');
    expect(reloaded.accessToken, 'a2');
    expect(reloaded.phone, '9876543210', reason: 'a refresh keeps the phone');

    await reloaded.clearSession();
    final cleared = TokenStore();
    await cleared.load();
    expect(cleared.isSignedIn, isFalse);
  });
}
