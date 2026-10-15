import 'package:flutter/material.dart';

import 'claro_colors.dart';
import 'claro_palette.dart';
import 'claro_type.dart';

/// The app's two themes, built from our own tokens. Material's dynamic colour
/// stays rejected (design-system §8). Screens read colours from
/// `context.palette`; the colour schemes here backstop stock Material widgets
/// (dialogs, snack bars, text fields) so none of them looks out of place.
abstract final class ClaroTheme {
  static ThemeData get dark => darkFor(ClaroAccent.mint);

  static ThemeData get light => lightFor(ClaroAccent.mint);

  static ThemeData darkFor(ClaroAccent accent) => _build(
        palette: ClaroPalette.darkFor(accent),
        scheme: ColorScheme.dark(
          primary: accent.fill,
          onPrimary: ClaroColors.ink,
          secondary: accent.fill,
          onSecondary: ClaroColors.ink,
          surface: ClaroColors.inkPanel,
          onSurface: ClaroColors.onInk,
          surfaceContainerHighest: ClaroColors.inkPanelHigh,
          onSurfaceVariant: ClaroColors.onInkMuted,
          outline: ClaroColors.borderDark,
          error: ClaroColors.fault,
          onError: ClaroColors.ink,
        ),
      );

  static ThemeData lightFor(ClaroAccent accent) => _build(
        palette: ClaroPalette.lightFor(accent),
        scheme: ColorScheme.light(
          primary: accent.deep,
          onPrimary: ClaroColors.card,
          secondary: accent.fill,
          onSecondary: ClaroColors.ink,
          surface: ClaroColors.card,
          onSurface: ClaroColors.ink,
          surfaceContainerHighest: const Color(0xFFEFEFEC),
          onSurfaceVariant: const Color(0xFF6B6B66),
          outline: ClaroColors.border,
          error: ClaroColors.fault,
          onError: ClaroColors.card,
        ),
      );

  static ThemeData _build({required ClaroPalette palette, required ColorScheme scheme}) {
    return ThemeData(
      useMaterial3: true,
      brightness: palette.isDark ? Brightness.dark : Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.bg,
      fontFamily: 'PlusJakartaSans',
      extensions: [palette],
      dividerColor: palette.border,
      textTheme: TextTheme(
        headlineMedium: ClaroType.displayXl,
        headlineSmall: ClaroType.displayLg,
        titleLarge: ClaroType.title,
        titleMedium: ClaroType.subtitle,
        bodyMedium: ClaroType.body,
        labelLarge: ClaroType.label,
        labelSmall: ClaroType.caption,
      ).apply(bodyColor: palette.text, displayColor: palette.text),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: palette.isDark ? ClaroColors.card : ClaroColors.ink,
        contentTextStyle: ClaroType.body.copyWith(color: palette.isDark ? ClaroColors.ink : ClaroColors.onInk),
      ),
      dialogTheme: DialogThemeData(backgroundColor: palette.panel),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: palette.panel),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: palette.accentText),
    );
  }
}
