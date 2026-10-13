import 'package:flutter/material.dart';

import '../core/api/mock_claro_pulse_api.dart';
import '../core/services.dart';
import '../ui/auth/auth_screen.dart';
import '../ui/components/claro_logo_mark.dart';
import '../ui/home/home_screen.dart';
import 'theme/claro_colors.dart';
import 'theme/claro_dimens.dart';
import 'theme/claro_theme.dart';

/// The app root, ported from the Kotlin `MainActivity`.
///
/// Shows a brief splash while services start, then the sign-in screen or home.
/// Starts signed in when a saved session exists, so a restart doesn't demand a
/// fresh OTP. A rejected session from ANY background call (the auth
/// interceptor signals it) drops back to sign-in.
class ClaroPulseApp extends StatefulWidget {
  const ClaroPulseApp({super.key, this.createServices = AppServices.create});

  /// Replaceable in tests.
  final Future<AppServices> Function() createServices;

  @override
  State<ClaroPulseApp> createState() => _ClaroPulseAppState();
}

class _ClaroPulseAppState extends State<ClaroPulseApp> {
  AppServices? _services;
  bool _signedIn = false;

  @override
  void initState() {
    super.initState();
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
    return MaterialApp(
      title: 'Claro Pulse',
      debugShowCheckedModeBanner: false,
      theme: ClaroTheme.dark,
      home: AnimatedSwitcher(
        duration: ClaroMotion.base,
        child: _buildHome(),
      ),
    );
  }

  Widget _buildHome() {
    final services = _services;
    if (services == null) return const _Splash(key: ValueKey('splash'));

    if (_signedIn) {
      return HomeScreen(
        key: const ValueKey('home'),
        services: services,
        onLogout: _signOut,
      );
    }
    return AuthScreen(
      key: const ValueKey('auth'),
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
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ClaroColors.ink,
      body: Center(child: ClaroLogoMark()),
    );
  }
}
