import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../state/session_controller.dart';
import '../../widgets/buttons.dart';
import '../../widgets/media.dart';
import '../../widgets/surfaces.dart';

/// The rest countdown.
///
/// Resting the right amount is the thing beginners get most wrong -- they either
/// rush a heavy set or spend three minutes on a curl -- so the app just runs it
/// for them. The panel rises from the bottom edge when a set is logged and slides
/// back the same way, which keeps the spatial relationship honest.
class RestTimerPanel extends ConsumerWidget {
  const RestTimerPanel({super.key, required this.state});

  final RestTimerState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(restTimerProvider.notifier);
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final finished = !state.running && state.remaining <= 0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: FDur.sheet,
      curve: FCurve.drawer,
      builder: (context, t, child) => Transform.translate(
        offset: Offset(0, (1 - t) * 180),
        child: Opacity(opacity: t, child: child),
      ),
      child: FGlassBar(
        blur: 30,
        opacity: 0.9,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            FSpace.gutter,
            FSpace.lg,
            FSpace.gutter,
            bottomInset + FSpace.lg,
          ),
          child: Row(
            children: [
              // The ring empties as the rest runs down, so the remaining time is
              // legible as a shape from across a gym floor, not just as digits.
              ProgressRingCountdown(
                progress: 1 - state.progress,
                seconds: state.remaining,
                finished: finished,
              ),
              const SizedBox(width: FSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      finished ? 'Rest over' : 'Resting',
                      style: FType.h3.copyWith(
                        color: finished ? FColors.emerald : FColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      finished
                          ? 'Go when you are ready.'
                          : 'Get set up for your next set.',
                      style: FType.caption.copyWith(color: FColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (!finished) ...[
                FButton(
                  label: '+15s',
                  variant: FButtonVariant.secondary,
                  size: FButtonSize.sm,
                  onPressed: () => controller.add(15),
                ),
                const SizedBox(width: FSpace.sm),
              ],
              FButton(
                label: finished ? 'Dismiss' : 'Skip',
                variant: finished
                    ? FButtonVariant.primary
                    : FButtonVariant.secondary,
                size: FButtonSize.sm,
                onPressed: controller.skip,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The countdown dial.
class ProgressRingCountdown extends StatelessWidget {
  const ProgressRingCountdown({
    super.key,
    required this.progress,
    required this.seconds,
    required this.finished,
  });

  final double progress;
  final int seconds;
  final bool finished;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Linear, and retargeted every second rather than replayed: the ring
          // has to track real time, so any easing would be a lie.
          TweenAnimationBuilder<double>(
            tween: Tween(begin: progress, end: progress),
            duration: const Duration(milliseconds: 950),
            curve: Curves.linear,
            builder: (context, t, _) => CustomPaint(
              size: const Size(58, 58),
              painter: _CountdownPainter(
                progress: t.clamp(0.0, 1.0),
                finished: finished,
              ),
            ),
          ),
          if (finished)
            const FIcon(FIcons.check, size: 22, color: FColors.emerald)
          else
            Text(
              _format(seconds),
              style: FType.num.copyWith(
                fontWeight: FontWeight.w700,
                // The last five seconds turn accent -- an early warning that
                // does not require reading the number.
                color: seconds <= 5 ? FColors.blue : FColors.text,
              ),
            ),
        ],
      ),
    );
  }

  static String _format(int seconds) {
    if (seconds < 60) return '$seconds';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _CountdownPainter extends CustomPainter {
  _CountdownPainter({required this.progress, required this.finished});

  final double progress;
  final bool finished;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 3.5;
    final tone = finished ? FColors.emerald : FColors.blue;
    final rect = (Offset.zero & size).deflate(stroke / 2);

    canvas.drawArc(
      rect,
      0,
      6.2832,
      false,
      Paint()
        ..color = FColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0 && !finished) return;

    canvas.drawArc(
      rect,
      -1.5708,
      6.2832 * (finished ? 1 : progress),
      false,
      Paint()
        ..color = tone
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter old) =>
      old.progress != progress || old.finished != finished;
}
