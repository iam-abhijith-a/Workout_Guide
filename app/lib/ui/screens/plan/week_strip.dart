import 'package:flutter/widgets.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/theme/typography.dart';
import '../../../data/models/session.dart';
import '../../widgets/media.dart';

/// The week at a glance: seven days, with the ones you trained filled in.
///
/// Deliberately the *week*, not a daily streak. A daily streak punishes exactly
/// the rest days a beginner needs, and the first miss tends to end the habit --
/// so the unit of consistency here is the week, which is also the unit the plan
/// is written in.
class WeekStrip extends StatelessWidget {
  const WeekStrip({super.key, required this.target, required this.sessions});

  final int target;
  final List<WorkoutSession> sessions;

  static const _labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = now.weekday - 1;
    final monday = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: today));

    final trained = <int>{
      for (final session in sessions)
        DateTime(
          session.startedAt.year,
          session.startedAt.month,
          session.startedAt.day,
        ).difference(monday).inDays,
    };

    final done = sessions.length;
    final metTarget = done >= target;

    return Column(
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              Expanded(
                child: _DayCell(
                  label: _labels[i],
                  trained: trained.contains(i),
                  isToday: i == today,
                  isPast: i < today,
                  // Later days settle in later, so the row fills left to right
                  // the way a week actually runs.
                  delay: Duration(milliseconds: 60 + i * 35),
                ),
              ),
              if (i != 6) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: FSpace.md),
        Row(
          children: [
            FIcon(
              metTarget ? FIcons.check : FIcons.target,
              size: 14,
              color: metTarget ? FColors.emerald : FColors.textMuted,
            ),
            const SizedBox(width: FSpace.sm),
            Text(
              metTarget ? 'Target hit' : '$done of $target sessions',
              style: FType.caption.copyWith(
                color: metTarget ? FColors.emerald : FColors.textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// One day.
///
/// The letter lives *inside* the cell rather than under it: a label beneath an
/// empty box reads as a caption for nothing, and it doubles the height the
/// strip needs for no extra information.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.trained,
    required this.isToday,
    required this.isPast,
    required this.delay,
  });

  final String label;
  final bool trained;
  final bool isToday;
  final bool isPast;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final total = FDur.slow + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: FCurve.out,
      ),
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: trained
                ? FColors.primary
                : (isToday ? FColors.surface : FColors.muted),
            borderRadius: FRadius.rMd,
            border: Border.all(
              color: trained
                  ? FColors.primary
                  : (isToday ? FColors.primary : const Color(0x00000000)),
              width: isToday && !trained ? 1.5 : 1,
            ),
          ),
          child: Center(
            child: trained
                ? const FIcon(FIcons.check, size: 15, color: FColors.onPrimary)
                : Text(
                    label,
                    style: FType.caption.copyWith(
                      color: isToday
                          ? FColors.text
                          : (isPast ? FColors.textMuted : FColors.textFaint),
                      fontWeight: isToday ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
