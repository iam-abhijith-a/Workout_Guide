import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../data/content/muscle_map.dart';

/// An anatomical figure with the worked muscles lit up.
///
/// A name like "latissimus dorsi" tells a beginner nothing. Showing them where
/// it is on a body does, instantly and without reading. The highlight fades up
/// rather than switching on, so the eye is drawn to the change rather than
/// having to hunt for what is different.
class BodyMap extends StatelessWidget {
  const BodyMap({
    super.key,
    required this.primary,
    this.secondary = const {},
    this.height = 210,
    this.showBothSides = true,
    this.animate = true,
  });

  /// Regions to light at full strength -- the muscle the exercise targets.
  final Set<MuscleRegion> primary;

  /// Supporting muscles, drawn at lower intensity so the hierarchy is obvious
  /// at a glance rather than needing a legend.
  final Set<MuscleRegion> secondary;

  final double height;

  /// Some exercises work only front or only back. Showing both anyway keeps the
  /// figure a fixed size across the app, which stops the layout jumping between
  /// exercises.
  final bool showBothSides;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final reduce = reduceMotionOf(context) || !animate;
    return SizedBox(
      height: height,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduce ? 1 : 0, end: 1),
        duration: FDur.ceremony,
        curve: FCurve.out,
        builder: (context, t, _) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: _FigureSide(
                front: true,
                primary: primary,
                secondary: secondary,
                progress: t,
              ),
            ),
            if (showBothSides)
              Expanded(
                child: _FigureSide(
                  front: false,
                  primary: primary,
                  secondary: secondary,
                  // Back lights a beat after the front, so the two figures read
                  // as one sequence rather than a simultaneous flash.
                  progress: (t * 1.25 - 0.25).clamp(0.0, 1.0),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FigureSide extends StatelessWidget {
  const _FigureSide({
    required this.front,
    required this.primary,
    required this.secondary,
    required this.progress,
  });

  final bool front;
  final Set<MuscleRegion> primary;
  final Set<MuscleRegion> secondary;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _BodyPainter(
              front: front,
              primary: primary,
              secondary: secondary,
              progress: progress,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: FSpace.sm),
        Text(front ? 'FRONT' : 'BACK', style: FType.caption),
      ],
    );
  }
}

/// Draws the figure from vector paths on a 100x220 grid.
///
/// Hand-built rather than loaded from an SVG so each muscle is a separately
/// addressable path that can be lit, tinted and animated independently -- which
/// is the entire point of having a body map rather than a picture of one.
class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.front,
    required this.primary,
    required this.secondary,
    required this.progress,
  });

  final bool front;
  final Set<MuscleRegion> primary;
  final Set<MuscleRegion> secondary;
  final double progress;

  static const _gw = 100.0;
  static const _gh = 220.0;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = (size.width / _gw).clamp(0.0, size.height / _gh);
    canvas.save();
    canvas.translate(
      (size.width - _gw * scale) / 2,
      (size.height - _gh * scale) / 2,
    );
    canvas.scale(scale);

    final silhouette = Paint()
      ..color = FColors.muted
      ..style = PaintingStyle.fill;
    final outline = Paint()
      ..color = FColors.borderStrong
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final part in _silhouette(front)) {
      canvas.drawPath(part, silhouette);
      canvas.drawPath(part, outline);
    }

    for (final entry in _muscles(front).entries) {
      final region = entry.key;
      final isPrimary = primary.contains(region);
      final isSecondary = secondary.contains(region);
      if (!isPrimary && !isSecondary) continue;

      final colour = regionColor(region);
      // Primary and secondary differ in opacity, not hue: same muscle family,
      // different amount of work.
      final target = isPrimary ? 1.0 : 0.34;
      final alpha = target * progress;

      for (final path in entry.value) {
        canvas.drawPath(
          path,
          Paint()
            ..color = colour.withValues(alpha: alpha)
            ..style = PaintingStyle.fill,
        );
        canvas.drawPath(
          path,
          Paint()
            ..color = colour.withValues(alpha: alpha)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }

    canvas.restore();
  }

  // -- Silhouette -------------------------------------------------------------

  List<Path> _silhouette(bool front) {
    final head = Path()..addOval(const Rect.fromLTWH(41, 4, 18, 22));
    final neck = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(45, 24, 10, 8),
          const Radius.circular(3),
        ),
      );

    final torso = Path()
      ..moveTo(50, 30)
      ..lineTo(68, 37) // shoulder
      ..lineTo(71, 52)
      ..lineTo(66, 78) // waist taper
      ..lineTo(64, 100)
      ..lineTo(50, 104)
      ..lineTo(36, 100)
      ..lineTo(34, 78)
      ..lineTo(29, 52)
      ..lineTo(32, 37)
      ..close();

    final leftArm = Path()
      ..moveTo(29, 40)
      ..lineTo(22, 46)
      ..lineTo(17, 74)
      ..lineTo(13, 100)
      ..lineTo(19, 102)
      ..lineTo(24, 76)
      ..lineTo(31, 52)
      ..close();
    final rightArm = Path()
      ..moveTo(71, 40)
      ..lineTo(78, 46)
      ..lineTo(83, 74)
      ..lineTo(87, 100)
      ..lineTo(81, 102)
      ..lineTo(76, 76)
      ..lineTo(69, 52)
      ..close();

    final leftLeg = Path()
      ..moveTo(36, 100)
      ..lineTo(48, 102)
      ..lineTo(47, 150)
      ..lineTo(45, 206)
      ..lineTo(36, 206)
      ..lineTo(35, 150)
      ..close();
    final rightLeg = Path()
      ..moveTo(64, 100)
      ..lineTo(52, 102)
      ..lineTo(53, 150)
      ..lineTo(55, 206)
      ..lineTo(64, 206)
      ..lineTo(65, 150)
      ..close();

    return [head, neck, torso, leftArm, rightArm, leftLeg, rightLeg];
  }

  // -- Muscle groups ----------------------------------------------------------
  // Each entry is a list because most muscles appear twice, once per side.

  Map<MuscleRegion, List<Path>> _muscles(bool front) =>
      front ? _frontMuscles() : _backMuscles();

  static Path _blob(double l, double t, double w, double h, double r) => Path()
    ..addRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(l, t, w, h), Radius.circular(r)),
    );

  Map<MuscleRegion, List<Path>> _frontMuscles() => {
    MuscleRegion.neckFront: [_blob(45, 25, 10, 7, 3)],
    MuscleRegion.frontDelts: [
      _blob(28, 36, 12, 15, 5),
      _blob(60, 36, 12, 15, 5),
    ],
    MuscleRegion.sideDelts: [_blob(24, 39, 8, 13, 4), _blob(68, 39, 8, 13, 4)],
    MuscleRegion.chest: [_blob(36, 40, 13, 17, 4), _blob(51, 40, 13, 17, 4)],
    MuscleRegion.biceps: [_blob(20, 53, 9, 17, 4), _blob(71, 53, 9, 17, 4)],
    MuscleRegion.forearms: [_blob(16, 73, 8, 24, 4), _blob(76, 73, 8, 24, 4)],
    MuscleRegion.abs: [_blob(43, 59, 14, 34, 4)],
    MuscleRegion.obliques: [_blob(35, 60, 7, 32, 3), _blob(58, 60, 7, 32, 3)],
    MuscleRegion.quads: [_blob(35, 104, 13, 40, 6), _blob(52, 104, 13, 40, 6)],
    MuscleRegion.adductors: [
      _blob(45, 104, 5, 30, 2),
      _blob(50, 104, 5, 30, 2),
    ],
    MuscleRegion.shinsFront: [
      _blob(36, 152, 9, 40, 4),
      _blob(55, 152, 9, 40, 4),
    ],
  };

  Map<MuscleRegion, List<Path>> _backMuscles() => {
    MuscleRegion.neckBack: [_blob(45, 25, 10, 7, 3)],
    MuscleRegion.traps: [
      Path()
        ..moveTo(50, 31)
        ..lineTo(67, 38)
        ..lineTo(58, 60)
        ..lineTo(50, 63)
        ..lineTo(42, 60)
        ..lineTo(33, 38)
        ..close(),
    ],
    MuscleRegion.rearDelts: [
      _blob(26, 37, 11, 14, 5),
      _blob(63, 37, 11, 14, 5),
    ],
    MuscleRegion.upperBack: [
      _blob(38, 46, 11, 16, 3),
      _blob(51, 46, 11, 16, 3),
    ],
    MuscleRegion.lats: [
      Path()
        ..moveTo(34, 52)
        ..lineTo(45, 60)
        ..lineTo(44, 84)
        ..lineTo(34, 76)
        ..close(),
      Path()
        ..moveTo(66, 52)
        ..lineTo(55, 60)
        ..lineTo(56, 84)
        ..lineTo(66, 76)
        ..close(),
    ],
    MuscleRegion.lowerBack: [_blob(43, 78, 14, 18, 4)],
    MuscleRegion.triceps: [_blob(19, 53, 10, 18, 4), _blob(71, 53, 10, 18, 4)],
    MuscleRegion.forearmsBack: [
      _blob(15, 74, 8, 24, 4),
      _blob(77, 74, 8, 24, 4),
    ],
    MuscleRegion.glutes: [_blob(35, 98, 14, 20, 6), _blob(51, 98, 14, 20, 6)],
    MuscleRegion.hamstrings: [
      _blob(35, 120, 13, 32, 6),
      _blob(52, 120, 13, 32, 6),
    ],
    MuscleRegion.calves: [_blob(35, 156, 11, 34, 5), _blob(54, 156, 11, 34, 5)],
  };

  @override
  bool shouldRepaint(_BodyPainter old) =>
      old.progress != progress ||
      old.front != front ||
      !setEquals(old.primary, primary) ||
      !setEquals(old.secondary, secondary);
}

bool setEquals<T>(Set<T> a, Set<T> b) =>
    a.length == b.length && a.every(b.contains);

/// Names what the figure is showing.
///
/// The plain-English gloss is the whole point for a beginner: "lats" means
/// nothing until someone tells you it is the wide muscle down the side of your
/// back, and a body map without words teaches only half of that.
class MuscleLegend extends StatelessWidget {
  const MuscleLegend({
    super.key,
    required this.target,
    required this.secondary,
  });

  final String target;
  final List<String> secondary;

  @override
  Widget build(BuildContext context) {
    final explainer = explainMuscle(target);
    final primaryRegions = regionsForMuscle(target);
    final colour = primaryRegions.isEmpty
        ? FColors.textMuted
        : regionColor(primaryRegions.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: FSpace.sm),
            Text(_titleCase(target), style: FType.h3),
          ],
        ),
        if (explainer.isNotEmpty) ...[
          const SizedBox(height: FSpace.xs),
          Text(explainer, style: FType.small),
        ],
        if (secondary.isNotEmpty) ...[
          const SizedBox(height: FSpace.md),
          Text(
            'Also: ${secondary.map(_titleCase).join(', ')}',
            style: FType.small,
          ),
        ],
      ],
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

/// Resolves an exercise's target and secondary muscles into figure regions.
({Set<MuscleRegion> primary, Set<MuscleRegion> secondary}) regionsFor({
  required String target,
  required List<String> secondary,
}) {
  final p = regionsForMuscle(target).toSet();
  final s = <MuscleRegion>{};
  for (final muscle in secondary) {
    s.addAll(regionsForMuscle(muscle));
  }
  // A muscle cannot be both the point of the exercise and an afterthought.
  s.removeAll(p);
  return (primary: p, secondary: s);
}
