import 'package:flutter/material.dart';

import 'claro_colors.dart';

/// The colours screens use, by ROLE rather than by name, so every screen works
/// in both the dark and the light theme.
///
/// Read it with `context.palette`. Rules:
/// - [accent] is a FILL (buttons, selected chips, glows). Text or icons on it use [onAccent].
/// - Green text and icons use [accentText]: mint on dark, the deeper green on
///   light, because mint text on white is unreadable (design-system §2.4).
/// - The same goes for [warnText] and [faultText] versus their fill colours.
/// The accent colours a farmer can choose in Profile → Appearance.
///
/// [fill] is bright, for buttons, chips and glows, always with dark text on it.
/// [deep] is the readable version for green/blue/etc. TEXT on light backgrounds.
enum ClaroAccent {
  mint('Mint', ClaroColors.mint, ClaroColors.mintDeep),
  sky('Sky', Color(0xFF6CC8FF), Color(0xFF0B6A9E)),
  teal('Teal', Color(0xFF4FE3D1), Color(0xFF0B7A6E)),
  lilac('Lilac', Color(0xFFC3B2FF), Color(0xFF5B43C7));

  const ClaroAccent(this.label, this.fill, this.deep);
  final String label;
  final Color fill;
  final Color deep;
}

@immutable
class ClaroPalette extends ThemeExtension<ClaroPalette> {
  const ClaroPalette({
    required this.isDark,
    required this.bg,
    required this.panel,
    required this.panelHigh,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.accentText,
    required this.onAccent,
    required this.fault,
    required this.faultText,
    required this.warn,
    required this.warnText,
  });

  final bool isDark;

  /// Screen background.
  final Color bg;

  /// Card / panel surface.
  final Color panel;

  /// A surface inside a panel (inputs, icon tiles).
  final Color panelHigh;

  /// Hairlines and card borders.
  final Color border;
  final Color text;
  final Color textMuted;
  final Color accent;
  final Color accentText;
  final Color onAccent;
  final Color fault;
  final Color faultText;
  final Color warn;
  final Color warnText;

  static final ClaroPalette dark = ClaroPalette(
    isDark: true,
    bg: ClaroColors.ink,
    panel: ClaroColors.inkPanel,
    panelHigh: ClaroColors.inkPanelHigh,
    border: ClaroColors.borderDark,
    text: ClaroColors.onInk,
    textMuted: ClaroColors.onInkMuted,
    accent: ClaroColors.mint,
    accentText: ClaroColors.mint,
    onAccent: ClaroColors.ink,
    fault: ClaroColors.fault,
    faultText: ClaroColors.fault,
    warn: ClaroColors.warn,
    warnText: ClaroColors.warn,
  );

  static const ClaroPalette light = ClaroPalette(
    isDark: false,
    bg: ClaroColors.surface,
    panel: ClaroColors.card,
    panelHigh: Color(0xFFEFEFEC),
    border: ClaroColors.border,
    text: ClaroColors.ink,
    // Darker than the design system's Muted so small grey text stays readable on white.
    textMuted: Color(0xFF6B6B66),
    accent: ClaroColors.mint,
    accentText: ClaroColors.mintDeep,
    onAccent: ClaroColors.ink,
    fault: ClaroColors.fault,
    faultText: Color(0xFFC9363B),
    warn: ClaroColors.warn,
    warnText: Color(0xFF9A5B00),
  );

  /// The dark palette with the chosen accent.
  static ClaroPalette darkFor(ClaroAccent a) => dark._withAccent(fill: a.fill, text: a.fill);

  /// The light palette with the chosen accent (deeper shade for text).
  static ClaroPalette lightFor(ClaroAccent a) => light._withAccent(fill: a.fill, text: a.deep);

  ClaroPalette _withAccent({required Color fill, required Color text}) => ClaroPalette(
        isDark: isDark,
        bg: bg,
        panel: panel,
        panelHigh: panelHigh,
        border: border,
        text: this.text,
        textMuted: textMuted,
        accent: fill,
        accentText: text,
        onAccent: onAccent,
        fault: fault,
        faultText: faultText,
        warn: warn,
        warnText: warnText,
      );

  @override
  ClaroPalette copyWith() => this;

  @override
  ClaroPalette lerp(ClaroPalette? other, double t) => (other == null || t < 0.5) ? this : other;
}

extension ClaroPaletteContext on BuildContext {
  ClaroPalette get palette => Theme.of(this).extension<ClaroPalette>() ?? ClaroPalette.dark;
}
