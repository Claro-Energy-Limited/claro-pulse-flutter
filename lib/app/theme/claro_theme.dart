import 'package:flutter/material.dart';

import 'claro_colors.dart';
import 'claro_palette.dart';
import 'claro_type.dart';

/// The app's two themes, built from our own tokens. Material's dynamic colour
/// stays rejected (design-system §8). Screens read colours from
/// `context.palette`; the colour schemes here backstop stock Material widgets
/// (dialogs, snack bars, text fields) so none of them looks out of place.
abstract final class ClaroTheme {
  static ThemeData get dark => _build(
        palette: ClaroPalette.dark,
        scheme: ColorScheme.dark(
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
        ),
      );

  static ThemeData get light => _build(
        palette: ClaroPalette.light,
        scheme: const ColorScheme.light(
          primary: ClaroColors.mintDeep,
          onPrimary: ClaroColors.card,
          secondary: ClaroColors.mint,
          onSecondary: ClaroColors.ink,
          surface: ClaroColors.card,
          onSurface: ClaroColors.ink,
          surfaceContainerHighest: Color(0xFFEFEFEC),
          onSurfaceVariant: Color(0xFF6B6B66),
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
