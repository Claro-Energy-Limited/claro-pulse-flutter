import 'package:flutter/material.dart';

import 'claro_colors.dart';

/// The colours screens use, by ROLE rather than by name, so every screen works
/// in both the dark and the light theme.
///
/// Read it with `context.palette`. Rules:
/// - [accent] is a FILL (buttons, selected chips, glows). Text or icons on it use [onAccent].
/// - Accent text and icons use [accentText]: a lighter shade on dark, a deeper
///   one on light, because the fill colour as text is unreadable on one of the
///   two (design-system §2.4).
/// - The same goes for [warnText] and [faultText] versus their fill colours.
/// - "Running / live / healthy / success" is [ok] / [okText], always green,
///   whatever accent the farmer picked: a running pump must never look like a
///   brand-red fault.
/// The accent colours a farmer can choose in Profile → Appearance.
///
/// [fill] is for buttons, chips and glows, with [onFill] text on it.
/// [deep] is the readable version for accent TEXT on light backgrounds,
/// [bright] the readable version on dark ones.
///
/// [claroRed] (the logo red) is the default since the red theme (13 Nov 2026).
/// It replaced Mint: a farmer who had saved Mint falls back to the default.
enum ClaroAccent {
  claroRed('Claro Red', ClaroColors.brand, ClaroColors.brandDeep, ClaroColors.brandBright, ClaroColors.onBrand),
  sky('Sky', Color(0xFF6CC8FF), Color(0xFF0B6A9E), Color(0xFF6CC8FF), ClaroColors.ink),
  teal('Teal', Color(0xFF4FE3D1), Color(0xFF0B7A6E), Color(0xFF4FE3D1), ClaroColors.ink),
  lilac('Lilac', Color(0xFFC3B2FF), Color(0xFF5B43C7), Color(0xFFC3B2FF), ClaroColors.ink);

  const ClaroAccent(this.label, this.fill, this.deep, this.bright, this.onFill);
  final String label;
  final Color fill;
  final Color deep;
  final Color bright;
  final Color onFill;

  /// What the app uses until the farmer picks something else.
  static const ClaroAccent standard = ClaroAccent.claroRed;
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
    required this.ok,
    required this.okText,
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

  /// Status green (running / live / healthy) as a fill or glow.
  final Color ok;

  /// Status green as text or icons, readable on this theme's surfaces.
  final Color okText;

  static final ClaroPalette dark = ClaroPalette(
    isDark: true,
    bg: ClaroColors.ink,
    panel: ClaroColors.inkPanel,
    panelHigh: ClaroColors.inkPanelHigh,
    border: ClaroColors.borderDark,
    text: ClaroColors.onInk,
    textMuted: ClaroColors.onInkMuted,
    accent: ClaroColors.brand,
    accentText: ClaroColors.brandBright,
    onAccent: ClaroColors.onBrand,
    fault: ClaroColors.fault,
    faultText: ClaroColors.fault,
    warn: ClaroColors.warn,
    warnText: ClaroColors.warn,
    ok: ClaroColors.mint,
    okText: ClaroColors.mint,
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
    accent: ClaroColors.brand,
    accentText: ClaroColors.brandDeep,
    onAccent: ClaroColors.onBrand,
    fault: ClaroColors.fault,
    faultText: Color(0xFFC9363B),
    warn: ClaroColors.warn,
    warnText: Color(0xFF9A5B00),
    ok: ClaroColors.mint,
    okText: ClaroColors.mintDeep,
  );

  /// The dark palette with the chosen accent.
  static ClaroPalette darkFor(ClaroAccent a) => dark._withAccent(fill: a.fill, text: a.bright, on: a.onFill);

  /// The light palette with the chosen accent (deeper shade for text).
  static ClaroPalette lightFor(ClaroAccent a) => light._withAccent(fill: a.fill, text: a.deep, on: a.onFill);

  ClaroPalette _withAccent({required Color fill, required Color text, required Color on}) => ClaroPalette(
        isDark: isDark,
        bg: bg,
        panel: panel,
        panelHigh: panelHigh,
        border: border,
        text: this.text,
        textMuted: textMuted,
        accent: fill,
        accentText: text,
        onAccent: on,
        fault: fault,
        faultText: faultText,
        warn: warn,
        warnText: warnText,
        ok: ok,
        okText: okText,
      );

  @override
  ClaroPalette copyWith() => this;

  @override
  ClaroPalette lerp(ClaroPalette? other, double t) => (other == null || t < 0.5) ? this : other;
}

extension ClaroPaletteContext on BuildContext {
  ClaroPalette get palette => Theme.of(this).extension<ClaroPalette>() ?? ClaroPalette.dark;
}
