import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// Circular progress. Used for the week's sessions and for rest.
///
/// The arc is drawn as a real stroked path so it can sweep, rather than a
/// rotating image -- and it starts at 12 o'clock, because anywhere else forces
/// the eye to work out where "empty" is.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    this.size = 64,
    this.strokeWidth = 5,
    this.color = FColors.primary,
    this.trackColor = FColors.border,
    this.child,
    this.animate = true,
    this.duration = FDur.ceremony,
    this.rounded = true,
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;
  final bool animate;
  final Duration duration;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    final target = progress.clamp(0.0, 1.0);
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: animate ? 0 : target, end: target),
        duration: animate ? duration : Duration.zero,
        curve: FCurve.out,
        builder: (context, t, inner) => CustomPaint(
          painter: _RingPainter(
            progress: t,
            strokeWidth: strokeWidth,
            color: color,
            trackColor: trackColor,
            rounded: rounded,
          ),
          child: Center(child: inner),
        ),
        child: child,
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
    required this.rounded,
  });

  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final bool rounded;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    ).deflate(strokeWidth / 2);

    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    canvas.drawArc(
      rect,
      -math.pi / 2, // twelve o'clock
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = rounded ? StrokeCap.round : StrokeCap.butt,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

/// Horizontal progress bar.
class FProgressBar extends StatelessWidget {
  const FProgressBar({
    super.key,
    required this.progress,
    this.height = 6,
    this.color = FColors.primary,
    this.trackColor = FColors.muted,
    this.duration = FDur.slow,
  });

  final double progress;
  final double height;
  final Color color;
  final Color trackColor;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: trackColor)),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
              duration: duration,
              curve: FCurve.out,
              builder: (context, t, _) => FractionallySizedBox(
                widthFactor: t,
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Onboarding progress.
///
/// A single continuous bar rather than a row of dots. Dots ask you to count
/// them to work out where you are; a bar is read at a glance, and it makes the
/// remaining distance feel small.
class StepProgress extends StatelessWidget {
  const StepProgress({super.key, required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FProgressBar(
            progress: count <= 1 ? 1 : index / (count - 1),
            height: 3,
            color: FColors.primary,
            trackColor: FColors.border,
            duration: FDur.slow,
          ),
        ),
        const SizedBox(width: FSpace.md),
        Text('${index + 1}/$count', style: FType.caption),
      ],
    );
  }
}

/// A labelled figure. The value can roll up from zero for numbers the user has
/// just earned.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.accent = false,
  });

  final String label;
  final String value;
  final String? suffix;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                value,
                style: FType.numLarge.copyWith(
                  color: accent ? FColors.primary : FColors.text,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (suffix != null) ...[
              const SizedBox(width: 3),
              Text(
                suffix!,
                style: FType.caption.copyWith(color: FColors.textMuted),
              ),
            ],
          ],
        ),
        const SizedBox(height: 3),
        Text(label, style: FType.caption.copyWith(color: FColors.textMuted)),
      ],
    );
  }
}

/// A simple column chart for weekly volume.
///
/// Bars grow from the baseline on first paint, staggered left to right, so the
/// chart reads as a timeline being filled in rather than a static image.
class VolumeChart extends StatelessWidget {
  const VolumeChart({
    super.key,
    required this.values,
    required this.labels,
    this.height = 120,
    this.color = FColors.primary,
  });

  final List<double> values;
  final List<String> labels;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return SizedBox(height: height);
    final peak = values.reduce(math.max);
    final reduce = reduceMotionOf(context);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: reduce ? 1 : 0,
                          end: peak == 0 ? 0 : values[i] / peak,
                        ),
                        duration: FDur.ceremony,
                        // Later bars start later: the chart draws itself in
                        // reading order.
                        curve: Interval(
                          (i / (values.length * 2)).clamp(0.0, 0.5),
                          1,
                          curve: FCurve.out,
                        ),
                        builder: (context, t, _) => FractionallySizedBox(
                          heightFactor: t.clamp(0.02, 1.0),
                          alignment: Alignment.bottomCenter,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              // The most recent week is the one you can still
                              // act on, so it is solid and the rest recede.
                              color: i == values.length - 1
                                  ? color
                                  : color.withValues(alpha: 0.22),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: FSpace.sm),
                    Text(
                      labels.length > i ? labels[i] : '',
                      style: FType.caption.copyWith(color: FColors.textFaint),
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Horizontal balance bars: how much work each body part has had.
///
/// This is the one chart that changes behaviour. Beginners overtrain what they
/// can see in the mirror; laying chest next to back makes the imbalance obvious
/// without anyone having to say it.
class BalanceBars extends StatelessWidget {
  const BalanceBars({super.key, required this.data, required this.colorOf});

  final List<({String label, int value})> data;
  final Color Function(String) colorOf;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final peak = data.map((d) => d.value).reduce(math.max);

    return Column(
      children: [
        for (var i = 0; i < data.length; i++)
          Padding(
            padding: EdgeInsets.only(
              bottom: i == data.length - 1 ? 0 : FSpace.md,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 86,
                  child: Text(
                    data[i].label,
                    style: FType.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(
                      begin: 0,
                      end: peak == 0 ? 0 : data[i].value / peak,
                    ),
                    duration: FDur.ceremony,
                    curve: Interval(
                      (i * 0.06).clamp(0.0, 0.5),
                      1,
                      curve: FCurve.out,
                    ),
                    builder: (context, t, _) => Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: t.clamp(0.0, 1.0),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: colorOf(
                              data[i].label,
                            ).withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: FSpace.md),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${data[i].value}',
                    style: FType.num.copyWith(color: FColors.textMuted),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
