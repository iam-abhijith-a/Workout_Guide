import 'package:flutter/widgets.dart';

import '../../core/motion/motion.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';

/// The Forge mark: a stylised plate-loaded bar, drawn stroke by stroke.
///
/// It draws itself rather than fading in. A line being made carries a sense of
/// something being built, which is the one idea the whole app is about -- and it
/// covers the cold-start work without resorting to a spinner.
class LogoMark extends StatelessWidget {
  const LogoMark({
    super.key,
    this.size = 48,
    this.progress = 1,
    this.color = FColors.text,
    this.accent = FColors.primary,
  });

  final double size;

  /// 0 to 1. Below 1 the mark is mid-draw.
  final double progress;
  final Color color;
  final Color accent;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: _LogoPainter(progress: progress, color: color, accent: accent),
    ),
  );
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({
    required this.progress,
    required this.color,
    required this.accent,
  });

  final double progress;
  final Color color;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 48;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Three strokes, drawn in sequence: the bar, then each plate. Sequential
    // rather than simultaneous, so the eye can follow the construction.
    final segments = <(Path, Color, double, double)>[
      (
        Path()
          ..moveTo(6 * k, 24 * k)
          ..lineTo(42 * k, 24 * k),
        color,
        0.0,
        0.42,
      ),
      (
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(11 * k, 13 * k, 8 * k, 22 * k),
            Radius.circular(3 * k),
          ),
        ),
        color,
        0.32,
        0.78,
      ),
      (
        Path()..addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(29 * k, 13 * k, 8 * k, 22 * k),
            Radius.circular(3 * k),
          ),
        ),
        accent,
        0.48,
        1.0,
      ),
    ];

    for (final (path, colour, start, end) in segments) {
      final local = ((progress - start) / (end - start)).clamp(0.0, 1.0);
      if (local <= 0) continue;
      stroke.color = colour;
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(0, metric.length * FCurve.out.transform(local)),
          stroke,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_LogoPainter old) => old.progress != progress;
}

/// Wordmark plus optional mark.
class LogoLockup extends StatelessWidget {
  const LogoLockup({
    super.key,
    this.size = 22,
    this.showMark = true,
    this.progress = 1,
  });

  final double size;
  final bool showMark;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showMark) ...[
          LogoMark(size: size * 1.3, progress: progress),
          SizedBox(width: size * 0.4),
        ],
        Text(
          'WORKOUT GUIDE',
          // The one place a size is passed directly: a wordmark is a mark, not
          // a text style, and it has to scale with whatever it sits beside.
          style: FType.h2.copyWith(
            fontFamily: 'InterDisplay',
            fontSize: size,
            fontWeight: FontWeight.w700,
            // Tight tracking: a wordmark at display weight
            // reads as one shape rather than a run of letters.
            letterSpacing: size * 0.09,
          ),
        ),
      ],
    );
  }
}

/// The launch screen.
///
/// It has a real job -- the exercise library is decoded off the main thread
/// while this is up -- so it lasts exactly as long as that takes plus enough to
/// finish the draw, and not a frame more.
class ForgeSplash extends StatefulWidget {
  const ForgeSplash({super.key, required this.onReady});

  /// Fires once the draw has finished. The caller decides where to go next.
  final VoidCallback onReady;

  @override
  State<ForgeSplash> createState() => _ForgeSplashState();
}

class _ForgeSplashState extends State<ForgeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void initState() {
    super.initState();
    _c.forward().whenComplete(widget.onReady);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FColors.canvas,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final draw = (_c.value / 0.7).clamp(0.0, 1.0);
            // The wordmark arrives only once the mark is essentially complete,
            // so the two do not compete for attention.
            final word = ((_c.value - 0.55) / 0.45).clamp(0.0, 1.0);
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LogoMark(size: 72, progress: draw),
                const SizedBox(height: FSpace.xl),
                Opacity(
                  opacity: FCurve.out.transform(word),
                  child: Transform.translate(
                    offset: Offset(0, (1 - FCurve.out.transform(word)) * 8),
                    child: Text(
                      'WORKOUT GUIDE',
                      style: FType.h2.copyWith(
                        fontFamily: 'InterDisplay',
                        letterSpacing: 6,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
