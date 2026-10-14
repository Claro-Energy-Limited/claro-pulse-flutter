import 'package:flutter/material.dart';

import 'claro_colors.dart';
import 'claro_type.dart';

/// Light and dark themes built from our design tokens.
///
/// Light mode is the app default, with dark mode and system default available
/// from the profile tab.
abstract final class ClaroTheme {
  static ThemeData get light {
    final scheme = ColorScheme.light(
      primary: ClaroColors.mintDeep,
      onPrimary: ClaroColors.card,
      secondary: ClaroColors.mintDeep,
      onSecondary: ClaroColors.card,
      surface: ClaroColors.surface,
      onSurface: ClaroColors.ink,
      surfaceContainerHighest: ClaroColors.card,
      onSurfaceVariant: ClaroColors.muted,
      outline: ClaroColors.border,
      error: ClaroColors.fault,
      onError: ClaroColors.card,
      errorContainer: ClaroColors.faultBg,
      onErrorContainer: ClaroColors.fault,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: ClaroColors.surface,
      fontFamily: 'PlusJakartaSans',
      textTheme: TextTheme(
        headlineMedium: ClaroType.displayXl.copyWith(color: ClaroColors.ink),
        headlineSmall: ClaroType.displayLg.copyWith(color: ClaroColors.ink),
        titleLarge: ClaroType.title.copyWith(color: ClaroColors.ink),
        titleMedium: ClaroType.subtitle.copyWith(color: ClaroColors.ink),
        bodyMedium: ClaroType.body.copyWith(color: ClaroColors.ink),
        labelLarge: ClaroType.label.copyWith(color: ClaroColors.ink),
        labelSmall: ClaroType.caption.copyWith(color: ClaroColors.ink),
      ).apply(bodyColor: ClaroColors.ink, displayColor: ClaroColors.ink),
    );
  }

  static ThemeData get dark {
    final scheme = ColorScheme.dark(
      primary: ClaroColors.mint,
      onPrimary: ClaroColors.ink,
      secondary: ClaroColors.mint,
      onSecondary: ClaroColors.ink,
      surface: ClaroColors.inkPanel,
      onSurface: ClaroColors.onInk,
      surfaceContainerHighest: ClaroColors.inkPanelHigh,
      onSurfaceVariant: ClaroColors.onInkMuted,
      outline: ClaroColors.borderDark,
      error: ClaroColors.fault,
      onError: ClaroColors.ink,
      errorContainer: ClaroColors.faultBg,
      onErrorContainer: ClaroColors.fault,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: ClaroColors.ink,
      fontFamily: 'PlusJakartaSans',
      // Same mapping as the Kotlin `Typography`, so plain Theme.of(context).textTheme also works.
      textTheme: TextTheme(
        headlineMedium: ClaroType.displayXl,
        headlineSmall: ClaroType.displayLg,
        titleLarge: ClaroType.title,
        titleMedium: ClaroType.subtitle,
        bodyMedium: ClaroType.body,
        labelLarge: ClaroType.label,
        labelSmall: ClaroType.caption,
      ).apply(bodyColor: ClaroColors.onInk, displayColor: ClaroColors.onInk),
    );
  }
}
