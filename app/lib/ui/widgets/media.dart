import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/motion/widgets.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/content/muscle_map.dart';
import '../../data/models/exercise.dart';

/// Static thumbnail for grids and lists.
///
/// Grids show the still frame, never the animation. Sixty simultaneously
/// animating WebPs would shred the scroll, and a wall of looping figures is
/// genuinely hard to read. The animation is the reward for opening one.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb({
    super.key,
    required this.exercise,
    this.size = 64,
    this.height,
    this.radius = FRadius.md,
    this.tinted = true,
  });

  final Exercise exercise;
  final double size;

  /// Defaults to [size]. A grid card sets it shorter than the width: the source
  /// stills are landscape, so a square crops the figure harder than a slightly
  /// wide box does, and it costs a row of cards per screen.
  final double? height;

  final double radius;

  /// Washes the plate in the body part's hue. The source images are all on the
  /// same near-white background, so without this a grid is a sea of identical
  /// pale squares.
  final bool tinted;

  @override
  Widget build(BuildContext context) {
    final tint = bodyPartColor(exercise.bodyPart);
    return Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        color: tinted ? FColors.wash(tint) : FColors.muted,
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        exercise.thumbAsset,
        fit: BoxFit.cover,
        // Decoding at display size rather than 180px keeps a long grid's memory
        // flat instead of climbing with every row.
        cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
        filterQuality: FilterQuality.medium,
        errorBuilder: (context, _, __) => const _MediaFallback(),
      ),
    );
  }
}

/// The looping demonstration.
///
/// Runs at whatever cadence the source encodes -- a one-second hold at each end
/// position, then a quick transit between them. That rhythm is doing real
/// teaching work, so it is preserved exactly rather than normalised to a
/// constant frame rate.
class ExerciseAnimation extends StatelessWidget {
  const ExerciseAnimation({
    super.key,
    required this.exercise,
    this.height = 220,
    this.radius = FRadius.lg,
  });

  final Exercise exercise;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: FColors.canvas,
        border: Border.all(color: FColors.border),
        borderRadius: BorderRadius.circular(radius),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(FSpace.sm),
        child: Image.asset(
          exercise.animAsset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
          gaplessPlayback: true,
          errorBuilder: (context, _, __) => const _MediaFallback(),
        ),
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  const _MediaFallback();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: FColors.muted,
    child: Center(
      child: FIcon(FIcons.dumbbell, size: 20, color: FColors.textFaint),
    ),
  );
}

/// A thumbnail with a caption, sized for a horizontal strip.
///
/// One component for every "here are some exercises" strip in the app. Two
/// near-identical copies is how strips end up 20px different from each other.
class ExerciseTile extends StatelessWidget {
  const ExerciseTile({
    super.key,
    required this.exercise,
    required this.onTap,
    this.meta,
    this.width = 108,
  });

  final Exercise exercise;
  final VoidCallback onTap;

  /// Optional second line -- a prescription, a piece of kit. Omitted when
  /// simply browsing.
  final String? meta;
  final double width;

  /// Height a strip must reserve for this tile.
  static const stripHeight = 168.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PressFx(
        onTap: onTap,
        scale: 0.96,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExerciseThumb(exercise: exercise, size: width),
            const SizedBox(height: FSpace.sm),
            // Fixed to two lines' worth of height whether the name needs one or
            // two, so the meta line sits on the same baseline right across a
            // strip. Ragged baselines are the thing that makes a row of cards
            // look assembled by hand.
            SizedBox(
              height: 32,
              child: Text(
                exercise.name,
                style: FType.caption.copyWith(color: FColors.text, height: 1.3),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (meta != null) Text(meta!, style: FType.caption, maxLines: 1),
          ],
        ),
      ),
    );
  }
}

/// An icon in a tinted, rounded plate.
///
/// The one device that keeps a greyscale interface from reading as monotonous:
/// a small wash of colour behind a tinted glyph. Colour here always means
/// something -- blue for information, amber for caution, emerald for done -- so
/// it never becomes decoration, and the surrounding page stays neutral.
class FIconTile extends StatelessWidget {
  const FIconTile({
    super.key,
    required this.icon,
    required this.tone,
    this.size = 32,
  });

  final FIconData icon;
  final Color tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: FColors.wash(tone),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Center(
        child: FIcon(icon, size: size * 0.5, color: tone),
      ),
    );
  }
}

/// Icons drawn as paths rather than pulled from a font.
///
/// Material's icon set is instantly recognisable as Material, which undercuts a
/// custom design system. These are drawn to one grid with one stroke weight, so
/// they sit together the way a real icon set does.
class FIcons {
  static const dumbbell = FIconData('dumbbell');
  static const home = FIconData('home');
  static const calendar = FIconData('calendar');
  static const search = FIconData('search');
  static const chart = FIconData('chart');
  static const book = FIconData('book');
  static const play = FIconData('play');
  static const check = FIconData('check');
  static const chevronRight = FIconData('chevronRight');
  static const chevronLeft = FIconData('chevronLeft');
  static const chevronDown = FIconData('chevronDown');
  static const close = FIconData('close');
  static const plus = FIconData('plus');
  static const minus = FIconData('minus');
  static const filter = FIconData('filter');
  static const sort = FIconData('sort');
  static const swap = FIconData('swap');
  static const timer = FIconData('timer');
  static const flame = FIconData('flame');
  static const star = FIconData('star');
  static const starFilled = FIconData('starFilled');
  static const settings = FIconData('settings');
  static const info = FIconData('info');
  static const alert = FIconData('alert');
  static const arrowRight = FIconData('arrowRight');
  static const skip = FIconData('skip');
  static const target = FIconData('target');
  static const sparkle = FIconData('sparkle');
  static const trash = FIconData('trash');
}

/// Identifies a glyph in [FIcons].
class FIconData {
  const FIconData(this.name);
  final String name;
}

/// Renders an [FIcons] glyph.
///
/// Inherits colour and size from the ambient [IconTheme] exactly like a Material
/// icon would, so it drops into any slot that expects one.
class FIcon extends StatelessWidget {
  const FIcon(this.icon, {super.key, this.size, this.color});

  final FIconData icon;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? 20;
    return SizedBox(
      width: s,
      height: s,
      child: CustomPaint(
        painter: _IconPainter(
          name: icon.name,
          color: color ?? theme.color ?? FColors.text,
        ),
      ),
    );
  }
}

class _IconPainter extends CustomPainter {
  _IconPainter({required this.name, required this.color});

  final String name;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Every glyph is drawn on a 24x24 grid, then scaled. One grid and one stroke
    // weight is the whole reason a set looks like a set.
    final k = size.width / 24;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    Offset p(double x, double y) => Offset(x * k, y * k);
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(p(x1, y1), p(x2, y2), stroke);

    switch (name) {
      case 'dumbbell':
        line(3, 12, 5, 12);
        line(19, 12, 21, 12);
        line(8, 12, 16, 12);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(5 * k, 8 * k, 3 * k, 8 * k),
            Radius.circular(1.2 * k),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(16 * k, 8 * k, 3 * k, 8 * k),
            Radius.circular(1.2 * k),
          ),
          stroke,
        );
      case 'home':
        canvas.drawPath(
          Path()
            ..moveTo(3 * k, 10.5 * k)
            ..lineTo(12 * k, 3.5 * k)
            ..lineTo(21 * k, 10.5 * k)
            ..lineTo(21 * k, 20 * k)
            ..lineTo(3 * k, 20 * k)
            ..close(),
          stroke,
        );
        line(9.5, 20, 9.5, 14);
        line(14.5, 20, 14.5, 14);
        line(9.5, 14, 14.5, 14);
      case 'calendar':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(3.5 * k, 5 * k, 17 * k, 15.5 * k),
            Radius.circular(2.5 * k),
          ),
          stroke,
        );
        line(3.5, 10, 20.5, 10);
        line(8, 3, 8, 6.5);
        line(16, 3, 16, 6.5);
        canvas.drawCircle(p(8.5, 14.5), 1.1 * k, fill);
        canvas.drawCircle(p(12.5, 14.5), 1.1 * k, fill);
      case 'search':
        canvas.drawCircle(p(10.5, 10.5), 6.5 * k, stroke);
        line(15.5, 15.5, 20.5, 20.5);
      case 'chart':
        line(3.5, 20, 20.5, 20);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(5 * k, 12 * k, 3.6 * k, 6 * k),
            Radius.circular(1 * k),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(10.2 * k, 8 * k, 3.6 * k, 10 * k),
            Radius.circular(1 * k),
          ),
          stroke,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(15.4 * k, 4.5 * k, 3.6 * k, 13.5 * k),
            Radius.circular(1 * k),
          ),
          stroke,
        );
      case 'book':
        canvas.drawPath(
          Path()
            ..moveTo(4 * k, 4.5 * k)
            ..lineTo(4 * k, 19 * k)
            ..cubicTo(4 * k, 19 * k, 7 * k, 17.5 * k, 12 * k, 18.5 * k)
            ..lineTo(12 * k, 6 * k)
            ..cubicTo(7 * k, 5 * k, 4 * k, 4.5 * k, 4 * k, 4.5 * k)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(20 * k, 4.5 * k)
            ..lineTo(20 * k, 19 * k)
            ..cubicTo(20 * k, 19 * k, 17 * k, 17.5 * k, 12 * k, 18.5 * k)
            ..lineTo(12 * k, 6 * k)
            ..cubicTo(17 * k, 5 * k, 20 * k, 4.5 * k, 20 * k, 4.5 * k)
            ..close(),
          stroke,
        );
      case 'play':
        canvas.drawPath(
          Path()
            ..moveTo(8 * k, 5.5 * k)
            ..lineTo(19 * k, 12 * k)
            ..lineTo(8 * k, 18.5 * k)
            ..close(),
          Paint()
            ..color = color
            ..style = PaintingStyle.fill
            ..strokeJoin = StrokeJoin.round,
        );
      case 'check':
        canvas.drawPath(
          Path()
            ..moveTo(5 * k, 12.5 * k)
            ..lineTo(10 * k, 17.5 * k)
            ..lineTo(19 * k, 6.5 * k),
          stroke,
        );
      case 'chevronRight':
        canvas.drawPath(
          Path()
            ..moveTo(9.5 * k, 5 * k)
            ..lineTo(16.5 * k, 12 * k)
            ..lineTo(9.5 * k, 19 * k),
          stroke,
        );
      case 'chevronLeft':
        canvas.drawPath(
          Path()
            ..moveTo(14.5 * k, 5 * k)
            ..lineTo(7.5 * k, 12 * k)
            ..lineTo(14.5 * k, 19 * k),
          stroke,
        );
      case 'chevronDown':
        canvas.drawPath(
          Path()
            ..moveTo(5 * k, 9.5 * k)
            ..lineTo(12 * k, 16.5 * k)
            ..lineTo(19 * k, 9.5 * k),
          stroke,
        );
      case 'arrowRight':
        line(4, 12, 19, 12);
        canvas.drawPath(
          Path()
            ..moveTo(13 * k, 6 * k)
            ..lineTo(19 * k, 12 * k)
            ..lineTo(13 * k, 18 * k),
          stroke,
        );
      case 'close':
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case 'plus':
        line(12, 5, 12, 19);
        line(5, 12, 19, 12);
      case 'minus':
        line(5, 12, 19, 12);
      case 'filter':
        line(3.5, 7, 20.5, 7);
        line(6.5, 12, 17.5, 12);
        line(9.5, 17, 14.5, 17);
      // Left-aligned and shortening, with an arrow: ordering, not narrowing.
      // Centred lines would read as the filter glyph at a glance.
      case 'sort':
        line(3.5, 6.5, 13, 6.5);
        line(3.5, 12, 10.5, 12);
        line(3.5, 17.5, 8, 17.5);
        line(17.5, 6, 17.5, 18);
        canvas.drawPath(
          Path()
            ..moveTo(14.5 * k, 15 * k)
            ..lineTo(17.5 * k, 18 * k)
            ..lineTo(20.5 * k, 15 * k),
          stroke,
        );
      case 'swap':
        canvas.drawPath(
          Path()
            ..moveTo(7 * k, 5 * k)
            ..lineTo(3.5 * k, 8.5 * k)
            ..lineTo(7 * k, 12 * k),
          stroke,
        );
        line(3.5, 8.5, 20.5, 8.5);
        canvas.drawPath(
          Path()
            ..moveTo(17 * k, 12 * k)
            ..lineTo(20.5 * k, 15.5 * k)
            ..lineTo(17 * k, 19 * k),
          stroke,
        );
        line(3.5, 15.5, 20.5, 15.5);
      case 'timer':
        canvas.drawCircle(p(12, 13.5), 7.5 * k, stroke);
        line(12, 9.5, 12, 13.5);
        line(12, 13.5, 15, 15.5);
        line(9.5, 3, 14.5, 3);
        line(12, 3, 12, 6);
      case 'flame':
        canvas.drawPath(
          Path()
            ..moveTo(12 * k, 3 * k)
            ..cubicTo(12 * k, 3 * k, 6 * k, 8 * k, 6 * k, 13.5 * k)
            ..cubicTo(6 * k, 17 * k, 8.7 * k, 20 * k, 12 * k, 20 * k)
            ..cubicTo(15.3 * k, 20 * k, 18 * k, 17 * k, 18 * k, 13.5 * k)
            ..cubicTo(18 * k, 8 * k, 12 * k, 3 * k, 12 * k, 3 * k)
            ..close(),
          stroke,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12 * k, 11 * k)
            ..cubicTo(12 * k, 11 * k, 9.5 * k, 13.5 * k, 9.5 * k, 15.5 * k)
            ..cubicTo(9.5 * k, 17 * k, 10.6 * k, 18 * k, 12 * k, 18 * k)
            ..cubicTo(13.4 * k, 18 * k, 14.5 * k, 17 * k, 14.5 * k, 15.5 * k)
            ..cubicTo(14.5 * k, 13.5 * k, 12 * k, 11 * k, 12 * k, 11 * k)
            ..close(),
          stroke,
        );
      case 'star':
      case 'starFilled':
        final star = Path();
        for (var i = 0; i < 5; i++) {
          final outer = -1.5708 + i * 1.2566;
          final inner = outer + 0.6283;
          final ox = 12 + 8.2 * math.cos(outer);
          final oy = 12 + 8.2 * math.sin(outer);
          final ix = 12 + 3.6 * math.cos(inner);
          final iy = 12 + 3.6 * math.sin(inner);
          if (i == 0) {
            star.moveTo(ox * k, oy * k);
          } else {
            star.lineTo(ox * k, oy * k);
          }
          star.lineTo(ix * k, iy * k);
        }
        star.close();
        canvas.drawPath(star, name == 'starFilled' ? fill : stroke);
      case 'settings':
        // Sliders rather than a cog: a spoked circle reads as a brightness
        // control at this size, which is the wrong promise entirely.
        line(3.5, 8, 20.5, 8);
        line(3.5, 16, 20.5, 16);
        final knob = Paint()..color = const Color(0xFFFFFFFF);
        canvas.drawCircle(p(9, 8), 2.7 * k, knob);
        canvas.drawCircle(p(9, 8), 2.7 * k, stroke);
        canvas.drawCircle(p(15, 16), 2.7 * k, knob);
        canvas.drawCircle(p(15, 16), 2.7 * k, stroke);
      case 'info':
        canvas.drawCircle(p(12, 12), 8.5 * k, stroke);
        line(12, 11, 12, 16.5);
        canvas.drawCircle(p(12, 7.8), 1.05 * k, fill);
      case 'alert':
        canvas.drawPath(
          Path()
            ..moveTo(12 * k, 3.5 * k)
            ..lineTo(21.5 * k, 20 * k)
            ..lineTo(2.5 * k, 20 * k)
            ..close(),
          stroke,
        );
        line(12, 9.5, 12, 14.5);
        canvas.drawCircle(p(12, 17.4), 1.05 * k, fill);
      case 'skip':
        canvas.drawPath(
          Path()
            ..moveTo(6 * k, 6 * k)
            ..lineTo(14 * k, 12 * k)
            ..lineTo(6 * k, 18 * k)
            ..close(),
          fill,
        );
        line(17, 6, 17, 18);
      case 'target':
        canvas.drawCircle(p(12, 12), 8.5 * k, stroke);
        canvas.drawCircle(p(12, 12), 4.8 * k, stroke);
        canvas.drawCircle(p(12, 12), 1.4 * k, fill);
      case 'sparkle':
        canvas.drawPath(
          Path()
            ..moveTo(12 * k, 3 * k)
            ..cubicTo(12 * k, 9 * k, 13 * k, 11 * k, 20 * k, 12 * k)
            ..cubicTo(13 * k, 13 * k, 12 * k, 15 * k, 12 * k, 21 * k)
            ..cubicTo(12 * k, 15 * k, 11 * k, 13 * k, 4 * k, 12 * k)
            ..cubicTo(11 * k, 11 * k, 12 * k, 9 * k, 12 * k, 3 * k)
            ..close(),
          stroke,
        );
      case 'trash':
        line(4, 6.5, 20, 6.5);
        line(9.5, 6.5, 9.5, 3.5);
        line(14.5, 6.5, 14.5, 3.5);
        line(9.5, 3.5, 14.5, 3.5);
        canvas.drawPath(
          Path()
            ..moveTo(6 * k, 6.5 * k)
            ..lineTo(7.2 * k, 20.5 * k)
            ..lineTo(16.8 * k, 20.5 * k)
            ..lineTo(18 * k, 6.5 * k),
          stroke,
        );
        line(10, 10.5, 10.4, 17);
        line(14, 10.5, 13.6, 17);
    }
  }

  @override
  bool shouldRepaint(_IconPainter old) =>
      old.name != name || old.color != color;
}

/// Fades an image in once it has actually decoded, instead of popping.
class FadeInImage extends StatelessWidget {
  const FadeInImage({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: FDur.slow,
    curve: FCurve.out,
    builder: (context, t, inner) => Opacity(opacity: t, child: inner),
    child: child,
  );
}
