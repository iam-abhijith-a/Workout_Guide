import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/motion/page_transitions.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../state/providers.dart';
import '../../widgets/app_shell.dart';

/// The moment the plan is generated.
///
/// Generation itself takes a few milliseconds, so this is honest theatre: it
/// narrates what the app actually did -- read the answers, filter the library,
/// balance the week -- because a plan that appears instantly reads as a
/// template, and one whose reasoning you watched reads as yours.
class BuildingPlanScreen extends ConsumerStatefulWidget {
  const BuildingPlanScreen({super.key, required this.next});

  /// Built here rather than handed a callback: the screen that pushed this one
  /// has already been replaced, so a closure capturing *its* context would be
  /// navigating from a dead element -- which left the app stuck on this screen.
  final WidgetBuilder next;

  @override
  ConsumerState<BuildingPlanScreen> createState() => _BuildingPlanScreenState();
}

class _BuildingPlanScreenState extends ConsumerState<BuildingPlanScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  int _line = 0;
  Timer? _lineTimer;
  late final List<String> _lines;

  @override
  void initState() {
    super.initState();

    final profile = ref.read(profileProvider);
    _lines = [
      'Reading your answers',
      'Filtering 1,324 movements down to what you can do',
      'Choosing a ${profile.daysPerWeek}-day split',
      'Balancing pushes against pulls',
      'Setting your sets, reps and rest',
      'Your plan is ready',
    ];

    // The plan itself is built by whoever pushed this screen, from an event
    // handler. Writing to a provider from initState is a Riverpod lifecycle
    // violation and throws.
    _c.forward();
    _lineTimer = Timer.periodic(const Duration(milliseconds: 430), (timer) {
      if (!mounted) return;
      if (_line >= _lines.length - 1) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        Future<void>.delayed(const Duration(milliseconds: 620), () {
          if (!mounted) return;
          Navigator.of(
            context,
          ).pushReplacement(FFadeRoute<void>(builder: widget.next));
        });
        return;
      }
      setState(() => _line++);
    });
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final done = _line >= _lines.length - 1;

    return FBackdrop(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(FSpace.x3l),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => CustomPaint(
                        painter: _AssemblyPainter(
                          progress: _c.value,
                          settled: done,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: FSpace.x4l),
                  // The line swaps in place rather than the list scrolling:
                  // one focal point, so the eye never has to re-find it.
                  SizedBox(
                    height: 52,
                    child: AnimatedSwitcher(
                      duration: FDur.slow,
                      switchInCurve: FCurve.out,
                      switchOutCurve: FCurve.exit,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: AnimatedBuilder(
                          animation: animation,
                          builder: (context, inner) => Transform.translate(
                            offset: Offset(0, (1 - animation.value) * 10),
                            child: inner,
                          ),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(_line),
                        children: [
                          Text(
                            _lines[_line],
                            style: done
                                ? FType.h2
                                : FType.h2.copyWith(
                                    color: FColors.textSecondary,
                                  ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
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

/// Fragments converging into the logo mark.
///
/// The visual argument of the screen: scattered pieces (1,324 exercises)
/// resolving into one ordered object (your plan).
class _AssemblyPainter extends CustomPainter {
  _AssemblyPainter({required this.progress, required this.settled});

  final double progress;
  final bool settled;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    final t = FCurve.out.transform(progress.clamp(0.0, 1.0));
    final tone = settled ? FColors.emerald : FColors.blue;

    // Fragments spiral inward and fade as they arrive, so the eye follows them
    // to the centre rather than watching them pop out of existence.
    for (var i = 0; i < 22; i++) {
      final angle = i * 0.9 + progress * 1.4;
      final startRadius = 62.0 + (i % 5) * 7;
      final radius = startRadius * (1 - t) + 26 * t;
      final alpha = (1 - t) * 0.7 + 0.08;
      canvas.drawCircle(
        centre + Offset(math.cos(angle) * radius, math.sin(angle) * radius),
        1.8,
        Paint()..color = tone.withValues(alpha: alpha),
      );
    }

    // The ring closes as the fragments land.
    canvas.drawArc(
      Rect.fromCircle(center: centre, radius: 34),
      -math.pi / 2,
      math.pi * 2 * t,
      false,
      Paint()
        ..color = tone
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // The bar-and-plates mark draws last, once there is a ring to sit inside.
    final markProgress = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
    if (markProgress > 0) {
      final stroke = Paint()
        ..color = FColors.text
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      final path = Path()
        ..moveTo(centre.dx - 15, centre.dy)
        ..lineTo(centre.dx + 15, centre.dy);
      for (final metric in path.computeMetrics()) {
        canvas.drawPath(
          metric.extractPath(
            0,
            metric.length * FCurve.out.transform(markProgress),
          ),
          stroke,
        );
      }
      if (markProgress > 0.4) {
        final plate = ((markProgress - 0.4) / 0.6).clamp(0.0, 1.0);
        for (final dx in [-11.0, 11.0]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(centre.dx + dx, centre.dy),
                width: 6,
                height: 18 * FCurve.out.transform(plate),
              ),
              const Radius.circular(2),
            ),
            stroke..color = dx < 0 ? FColors.text : tone,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_AssemblyPainter old) =>
      old.progress != progress || old.settled != settled;
}
