import 'package:flutter/widgets.dart';

/// Design tokens.
///
/// Light, greyscale, flat. There are no gradients anywhere in this app: depth
/// comes from a hairline border and a single tint of background, the way Linear
/// and shadcn do it. Colour is reserved for two jobs -- tinting an icon by what
/// it means, and washing a surface that needs to read as a different *kind* of
/// thing. Never for decoration.
abstract final class FColors {
  // -- Surfaces --------------------------------------------------------------
  // A four-step neutral ramp. Anything beyond this and surfaces stop being
  // distinguishable, so they stop carrying information.
  static const canvas = Color(0xFFFFFFFF); // page background
  static const surface = Color(
    0xFFFFFFFF,
  ); // cards sit flush, separated by border
  static const surfaceHover = Color(0xFFFAFAFA);
  static const muted = Color(0xFFF4F4F5); // inputs, tracks, wells
  static const mutedHover = Color(0xFFEBEBEE);

  // -- Borders ---------------------------------------------------------------
  // The primary structural device. Almost every boundary in the app is one of
  // these rather than a shadow or a fill.
  static const border = Color(0xFFE4E4E7);
  static const borderStrong = Color(0xFFD4D4D8);

  // -- Text ------------------------------------------------------------------
  static const text = Color(0xFF09090B); // headings, values
  static const textSecondary = Color(0xFF52525B); // body copy
  static const textMuted = Color(0xFF71717A); // supporting detail
  static const textFaint = Color(0xFFA1A1AA); // placeholders, disabled

  // -- Primary action --------------------------------------------------------
  // Near-black on white. The highest-contrast thing on any screen, so there is
  // never a question about what the main action is.
  static const primary = Color(0xFF18181B);
  static const primaryHover = Color(0xFF27272A);
  static const onPrimary = Color(0xFFFAFAFA);

  // -- Semantic accents ------------------------------------------------------
  // Used on icons and small marks, essentially never on large fills. Each has a
  // matching wash for surfaces that need to read as a callout.
  static const blue = Color(0xFF2563EB); // information, plan, timing
  static const violet = Color(0xFF7C3AED); // technique, cues
  static const emerald = Color(0xFF059669); // done, safe, beginner
  static const amber = Color(0xFFD97706); // caution, mistakes, intermediate
  static const rose = Color(0xFFE11D48); // destructive, advanced
  static const orange = Color(0xFFEA580C); // streak, effort
  static const teal = Color(0xFF0D9488); // progress, measurement
  static const indigo = Color(0xFF4F46E5); // learning

  /// Background tint for a callout. 8% is enough to separate a surface without
  /// it competing with the text on top of it.
  static Color wash(Color c) => c.withValues(alpha: 0.08);

  /// Hairline for a tinted surface, so a callout still reads as a card.
  static Color washBorder(Color c) => c.withValues(alpha: 0.20);

  // -- Body-part identity ----------------------------------------------------
  // Used only for the small dot on a library row and for the body map. Tuned
  // for legibility on white, which needs deeper values than a dark theme.
  static const partChest = blue;
  static const partBack = teal;
  static const partLegs = orange;
  static const partShoulders = violet;
  static const partArms = Color(0xFFDB2777); // pink
  static const partCore = amber;
  static const partCardio = Color(0xFF0891B2); // cyan
}

/// Spacing, on a strict 4px grid. Nothing in the app uses a value that is not
/// from this list.
abstract final class FSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double x3l = 32;
  static const double x4l = 40;
  static const double x5l = 48;

  /// Horizontal page gutter, identical on every screen so edges line up as you
  /// navigate between them.
  static const double gutter = 20;

  /// Vertical rhythm between major sections.
  static const double section = 28;
}

/// Corner radii. Small and consistent -- large radii read as consumer-app
/// friendly rather than as a tool.
abstract final class FRadius {
  static const double sm = 6;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double pill = 999;

  static const BorderRadius rSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius rMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius rLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius rXl = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius rPill = BorderRadius.all(Radius.circular(pill));
}

/// Elevation. Used sparingly: only things that genuinely float above the page
/// get a shadow, and it stays tight enough to read as a lift rather than a glow.
abstract final class FShadow {
  static const List<BoxShadow> sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const List<BoxShadow> md = [
    BoxShadow(color: Color(0x0D000000), blurRadius: 6, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x14000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> sheet = [
    BoxShadow(color: Color(0x1F000000), blurRadius: 32, offset: Offset(0, -4)),
  ];
}
