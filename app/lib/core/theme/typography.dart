import 'package:flutter/widgets.dart';

import 'tokens.dart';

/// The type scale.
///
/// Seven styles, and nothing in the app is allowed to invent an eighth or to
/// pass a one-off `fontSize`. A scale only does its job if it is the *only*
/// source of type, and the fastest way to make an interface look improvised is
/// twelve sizes that are each two pixels apart.
///
/// One family throughout: Inter for everything, InterDisplay only where text is
/// large enough for the display cut's tighter apertures to matter.
abstract final class FType {
  static const _display = 'InterDisplay';
  static const _sans = 'Inter';

  /// Numbers that change in place -- timers, weights, reps -- must not jitter as
  /// digits swap.
  static const _tabular = [FontFeature.tabularFigures()];

  /// Page title. One per screen.
  static const h1 = TextStyle(
    fontFamily: _display,
    fontSize: 26,
    height: 1.15,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6, // large text reads loose; tighten it
    color: FColors.text,
  );

  /// Card and section titles.
  static const h2 = TextStyle(
    fontFamily: _sans,
    fontSize: 17,
    height: 1.3,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.24,
    color: FColors.text,
  );

  /// Row titles, list items, anything that names a thing.
  static const h3 = TextStyle(
    fontFamily: _sans,
    fontSize: 14.5,
    height: 1.35,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: FColors.text,
  );

  /// Body copy.
  static const body = TextStyle(
    fontFamily: _sans,
    fontSize: 14,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: FColors.textSecondary,
  );

  /// Supporting detail under a title.
  static const small = TextStyle(
    fontFamily: _sans,
    fontSize: 13,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: FColors.textMuted,
  );

  /// Interactive labels: buttons, chips, tabs.
  static const label = TextStyle(
    fontFamily: _sans,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.06,
    color: FColors.text,
  );

  /// Section eyebrows and metadata. Positive tracking is doing real work at
  /// this size.
  static const caption = TextStyle(
    fontFamily: _sans,
    fontSize: 11.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
    color: FColors.textMuted,
  );

  /// Figures. Same sizes as the scale above, just tabular.
  static const num = TextStyle(
    fontFamily: _sans,
    fontSize: 13.5,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: FColors.text,
    fontFeatures: _tabular,
  );

  /// A headline figure: a stat, a set count.
  static const numLarge = TextStyle(
    fontFamily: _display,
    fontSize: 24,
    height: 1.1,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: FColors.text,
    fontFeatures: _tabular,
  );

  /// The rest-timer readout, the single largest thing in the app.
  static const numTimer = TextStyle(
    fontFamily: _display,
    fontSize: 34,
    height: 1,
    fontWeight: FontWeight.w700,
    letterSpacing: -1.2,
    color: FColors.text,
    fontFeatures: _tabular,
  );
}

/// Colour variants of the scale, so a screen never needs `copyWith` for the
/// common case of "same style, quieter".
extension FTypeTone on TextStyle {
  TextStyle get primary => copyWith(color: FColors.text);
  TextStyle get secondary => copyWith(color: FColors.textSecondary);
  TextStyle get muted => copyWith(color: FColors.textMuted);
  TextStyle get faint => copyWith(color: FColors.textFaint);
  TextStyle get inverse => copyWith(color: FColors.onPrimary);
  TextStyle tinted(Color c) => copyWith(color: c);
}
