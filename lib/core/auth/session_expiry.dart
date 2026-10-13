import 'package:flutter/foundation.dart';

/// How the auth interceptor tells the UI "the session just ended" from inside a
/// network call, ported from the Kotlin `SessionExpiryNotifier`.
///
/// The app root listens to [expired]; when it turns true, it drops back to the
/// sign-in screen and calls [acknowledge] so the same expiry doesn't fire twice.
class SessionExpiry {
  final ValueNotifier<bool> expired = ValueNotifier<bool>(false);

  void signalExpired() => expired.value = true;

  void acknowledge() => expired.value = false;
}
