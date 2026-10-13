import 'package:flutter/material.dart';

import 'claro_colors.dart';
import 'claro_type.dart';

/// One fixed dark theme built from our own tokens, ported from the Kotlin `Theme.kt`.
///
/// Material's dynamic colour stays rejected (design-system.md §8). The app runs
/// dark (black / white / green) by product decision. Screens pass explicit colours
/// anyway; this scheme backstops stock Material widgets so none of them draws a
/// white surface on a black screen.
abstract final class ClaroTheme {
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
