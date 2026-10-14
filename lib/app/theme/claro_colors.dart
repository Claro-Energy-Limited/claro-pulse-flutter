import 'package:flutter/material.dart';

/// Claro Pulse design tokens, ported 1:1 from the Kotlin app's `Color.kt`.
///
/// Source of truth: RMS `docs/design/design-system.md` §2. Do not add a colour here
/// that isn't in that table; derive a tint or shade from these instead.
abstract final class ClaroColors {
  // ── Core (§2.1) ─────────────────────────────────────────────────────────────
  /// Primary accent: healthy / active / positive.
  ///
  /// On white surfaces Mint is fill-only (about 1.25:1 contrast). On [ink] it is
  /// the readable green for text and icons (over 12:1), while [mintDeep] falls
  /// under 3:1 and must not carry text there.
  static const mint = Color(0xFF78FC90);

  /// Primary text on light; the app background on dark (which this app ships).
  static const ink = Color(0xFF111110);

  /// App background, light mode.
  static const surface = Color(0xFFF6F6F6);

  /// Card / panel surface, light mode.
  static const card = Color(0xFFFFFFFF);

  // ── Derived (§2.2) ──────────────────────────────────────────────────────────
  /// Green text/icons on light surfaces only (§2.4).
  static const mintDeep = Color(0xFF1F7A4C);
  static const mintBg = Color(0xFFE7FCEC);
  static const fault = Color(0xFFE5484D);
  static const faultBg = Color(0xFFFDECEC);
  static const warn = Color(0xFFF5A524);
  static const warnBg = Color(0xFFFEF4E6);
  static const offline = Color(0xFFC4C4BF);
  static const muted = Color(0xFF8A8A85);
  static const border = Color(0xFFE8E8E6);

  /// Body text where full [ink] is too heavy.
  static const inkSoft = Color(0xFF3A3A38);

  // ── Dark surfaces (derived from Ink and white, not new palette entries) ─────
  /// Card / panel on an [ink] screen.
  static final inkPanel = Color.lerp(ink, const Color(0xFFFFFFFF), 0.07)!;

  /// A panel above another panel (an input inside a card).
  static final inkPanelHigh = Color.lerp(ink, const Color(0xFFFFFFFF), 0.12)!;

  /// Hairline on dark. The light-mode [border] is far too bright here.
  static const borderDark = Color(0x1FFFFFFF); // white at 12%

  /// Body text on dark.
  static const onInk = Color(0xFFFFFFFF);

  /// Secondary text on dark: the dark-mode counterpart of [muted].
  static const onInkMuted = Color(0x99FFFFFF); // white at 60%
}

/// Dynamic theme color resolution helpers for Light and Dark modes.
extension ClaroThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// Screen background
  Color get bg => isDark ? ClaroColors.ink : ClaroColors.surface;

  /// Card or panel background
  Color get panel => isDark ? ClaroColors.inkPanel : ClaroColors.card;

  /// Input or nested card background
  Color get panelHigh => isDark ? ClaroColors.inkPanelHigh : const Color(0xFFF2F2F0);

  /// Primary body & title text
  Color get textPrimary => isDark ? ClaroColors.onInk : ClaroColors.ink;

  /// Muted / secondary caption text
  Color get textSecondary => isDark ? ClaroColors.onInkMuted : ClaroColors.muted;

  /// Card hairline border
  Color get border => isDark ? ClaroColors.borderDark : ClaroColors.border;

  /// Mint accent (brighter on dark, deeper for contrast on light)
  Color get brandMint => isDark ? ClaroColors.mint : ClaroColors.mintDeep;
}
