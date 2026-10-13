import 'dart:ui' show FontFeature, FontVariation;

import 'package:flutter/painting.dart';

/// Bundled in `assets/fonts` (declared in pubspec.yaml), not downloaded at runtime,
/// so the app renders correctly with no connectivity.
const _jakarta = 'PlusJakartaSans';

/// Every live/numeric readout uses this, with tabular figures (design-system.md §3).
const _mono = 'JetBrainsMono';

/// Both bundled fonts are variable fonts. `fontWeight` alone does not move a
/// variable font's weight axis, so each style also sets the `wght` variation.
TextStyle _style(
  String family,
  int weight,
  double size,
  double lineHeight, {
  bool tabular = false,
}) {
  return TextStyle(
    fontFamily: family,
    fontWeight: FontWeight.values[(weight ~/ 100) - 1],
    fontVariations: [FontVariation('wght', weight.toDouble())],
    fontFeatures: tabular ? const [FontFeature.tabularFigures()] : null,
    fontSize: size,
    height: lineHeight / size,
  );
}

/// Named type scale (design-system.md §3.1), ported 1:1 from the Kotlin `ClaroPulseType`.
/// Use only these; add a new one to the design doc (and here) before inventing a size.
abstract final class ClaroType {
  static final displayXl = _style(_jakarta, 600, 48, 52);
  static final displayLg = _style(_jakarta, 600, 34, 40);
  static final title = _style(_jakarta, 600, 20, 28);
  static final subtitle = _style(_jakarta, 500, 15, 22);
  static final body = _style(_jakarta, 400, 14, 21);
  static final label = _style(_jakarta, 500, 12, 16);
  static final caption = _style(_jakarta, 400, 11, 14);

  static final readoutXl = _style(_mono, 500, 44, 48, tabular: true);
  static final readoutLg = _style(_mono, 500, 28, 34, tabular: true);
  static final readout = _style(_mono, 400, 16, 22, tabular: true);
  static final readoutSm = _style(_mono, 400, 13, 18, tabular: true);
}
