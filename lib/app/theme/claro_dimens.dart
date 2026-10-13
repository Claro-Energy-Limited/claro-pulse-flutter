import 'package:flutter/widgets.dart';

/// Spacing scale (design-system.md §4). Only these values; nothing hardcoded inline.
abstract final class ClaroSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

/// Radius scale (design-system.md §4). Only these values.
abstract final class ClaroRadius {
  static const sm = BorderRadius.all(Radius.circular(8));
  static const md = BorderRadius.all(Radius.circular(12));

  /// 24: matches the web's auth card radius exactly.
  static const lg = BorderRadius.all(Radius.circular(24));

  /// Fully rounded ends. A large radius is clamped to half the height by Flutter.
  static const pill = BorderRadius.all(Radius.circular(999));

  /// Top-only rounding for a panel rising from the bottom edge; same 24 as [lg].
  static const sheet = BorderRadius.vertical(top: Radius.circular(24));
}

/// Motion durations (design-system.md §4). Animation signals a state change, never decoration.
abstract final class ClaroMotion {
  static const fast = Duration(milliseconds: 150);
  static const base = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

/// Stroke widths for the thin-line icon set (design-system.md §6.1). Only these two.
abstract final class ClaroStroke {
  static const double thin = 1.5;
  static const double regular = 2;
}
