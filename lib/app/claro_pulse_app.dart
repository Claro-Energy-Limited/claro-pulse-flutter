import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api/mock_claro_pulse_api.dart';
import '../core/services.dart';
import '../ui/auth/auth_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/splash/splash_screen.dart';
import 'theme/claro_dimens.dart';
import 'theme/claro_palette.dart';
import 'theme/claro_theme.dart';

/// The app root: splash while services start, then sign-in or home.
///
/// Starts signed in when a saved session exists, so a restart doesn't demand a
/// fresh OTP. A rejected session from ANY background call (the auth
/// interceptor signals it) drops back to sign-in.
class ClaroPulseApp extends StatefulWidget {
  const ClaroPulseApp({
    super.key,
    this.createServices = AppServices.create,
    this.minSplash = const Duration(milliseconds: 1600),
  });

  /// Replaceable in tests.
  final Future<AppServices> Function() createServices;

  /// The splash stays at least this long, so it reads as intentional rather
  /// than a flicker. Tests set it to zero.
  final Duration minSplash;

  @override
  State<ClaroPulseApp> createState() => _ClaroPulseAppState();
}

class _ClaroPulseAppState extends State<ClaroPulseApp> {
  AppServices? _services;
  bool _splashDone = false;
  bool _signedIn = false;
  Timer? _splashTimer;

  @override
  void initState() {
    super.initState();
    if (widget.minSplash == Duration.zero) {
      _splashDone = true;
    } else {
      _splashTimer = Timer(widget.minSplash, () {
        if (mounted) setState(() => _splashDone = true);
      });
    }
    widget.createServices().then((services) {
      if (!mounted) return;
      services.sessionExpiry.expired.addListener(_onSessionExpired);
      setState(() {
        _services = services;
        _signedIn = services.tokenStore.isSignedIn;
      });
    });
  }

  @override
  void dispose() {
    _splashTimer?.cancel();
    _services?.sessionExpiry.expired.removeListener(_onSessionExpired);
    super.dispose();
  }

  void _onSessionExpired() {
    final services = _services;
    if (services == null || !services.sessionExpiry.expired.value) return;
    services.sessionExpiry.acknowledge();
    setState(() => _signedIn = false);
  }

  Future<void> _signOut() async {
    await _services?.tokenStore.clearSession();
    if (mounted) setState(() => _signedIn = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = _services?.settings;
    // Follows the phone until the farmer picks Light or Dark in Profile; the
    // accent colour is their choice too.
    return ListenableBuilder(
      listenable: Listenable.merge([settings?.themeMode ?? _systemMode, settings?.accent ?? _mintAccent]),
      builder: (context, _) {
        final mode = settings?.themeMode.value ?? ThemeMode.system;
        final accent = settings?.accent.value ?? ClaroAccent.mint;
        return MaterialApp(
          title: 'Claro Pulse',
          debugShowCheckedModeBanner: false,
          theme: ClaroTheme.lightFor(accent),
          darkTheme: ClaroTheme.darkFor(accent),
          themeMode: mode,
          // Status bar icons: light on the dark theme, dark on the light theme.
          builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
            value: Theme.of(context).brightness == Brightness.dark
                ? SystemUiOverlayStyle.light.copyWith(statusBarColor: const Color(0x00000000))
                : SystemUiOverlayStyle.dark.copyWith(statusBarColor: const Color(0x00000000)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: AnimatedSwitcher(
            duration: ClaroMotion.slow,
            child: _buildHome(),
          ),
        );
      },
    );
  }

  static final ValueNotifier<ThemeMode> _systemMode = ValueNotifier(ThemeMode.system);
  static final ValueNotifier<ClaroAccent> _mintAccent = ValueNotifier(ClaroAccent.mint);

  /// The splash and sign-in screens are designed dark (photo, white logo), so
  /// they stay dark in both themes.
  Widget _dark(Widget child) => Theme(
        data: ClaroTheme.dark,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light.copyWith(statusBarColor: const Color(0x00000000)),
          child: child,
        ),
      );

  Widget _buildHome() {
    final services = _services;
    if (services == null || !_splashDone) {
      return KeyedSubtree(key: const ValueKey('splash'), child: _dark(const SplashScreen()));
    }

    if (_signedIn) {
      return HomeScreen(
        key: const ValueKey('home'),
        services: services,
        onLogout: _signOut,
      );
    }
    return KeyedSubtree(
      key: const ValueKey('auth'),
      child: _dark(
        AuthScreen(
          onSendOtp: services.api.requestOtp,
          onVerifyOtp: (phone, code) async {
            final tokens = await services.api.verifyOtp(phone, code);
            await services.tokenStore.saveSession(
              accessToken: tokens.accessToken,
              refreshToken: tokens.refreshToken,
              phone: phone,
            );
          },
          onAuthenticated: () => setState(() => _signedIn = true),
          otpHint: services.isMock ? 'Mock mode: use code ${MockClaroPulseApi.otpCode}' : null,
        ),
      ),
    );
  }
}
